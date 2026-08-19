//
//  MobileRemoveWalletNotificationViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemLocalization
import TangemUIUtils
import TangemMobileWalletSdk
import protocol TangemUI.FloatingSheetContentViewModel

final class MobileRemoveWalletNotificationViewModel: ObservableObject {
    @Injected(\.alertPresenter) private var alertPresenter: AlertPresenter

    var title: String {
        switch backupState {
        case .iCloudBackup:
            "Forget this wallet?"
        case .seedBackup, .noBackup:
            isICloudBackupFeatureAvailable
                ? "Forget this wallet?"
                : Localization.hwRemoveWalletNotificationTitle
        }
    }

    var description: String {
        switch backupState {
        case .iCloudBackup:
            "Wallet will be removed from this device. Your iCloud backup stays safe — you can restore this wallet anytime with your password."
        case .seedBackup:
            isICloudBackupFeatureAvailable
                ? "A backup for this wallet exists. Review it before forgetting to make sure you can recover later."
                : Localization.hwRemoveWalletNotificationDescriptionHasBackup
        case .noBackup:
            Localization.hwRemoveWalletNotificationDescriptionWithoutBackup
        }
    }

    var primaryAction: Action {
        makePrimaryAction()
    }

    var secondaryAction: Action {
        makeSecondaryAction()
    }

    var isICloudBackupFeatureAvailable: Bool {
        FeatureProvider.isAvailable(.mobileWalletBackup)
    }

    private var analyticsContextParams: Analytics.ContextParams {
        .custom(userWalletModel.analyticsContextData)
    }

    private var backupState: MobileRemoveWalletBackupState {
        removeManager.backupState
    }

    private let userWalletModel: UserWalletModel
    private let removeManager: MobileRemoveWalletManager
    private weak var coordinator: MobileRemoveWalletNotificationRoutable?

    init(
        userWalletModel: UserWalletModel,
        removeManager: MobileRemoveWalletManager,
        coordinator: MobileRemoveWalletNotificationRoutable
    ) {
        self.userWalletModel = userWalletModel
        self.removeManager = removeManager
        self.coordinator = coordinator

        if isICloudBackupFeatureAvailable {
            logForgetWalletRequestAnalytics()
        } else if backupState == .noBackup {
            logMobileBackupNeededAnalytics()
        }
    }
}

// MARK: - Internal methods

extension MobileRemoveWalletNotificationViewModel {
    func onCloseTap() {
        runTask(in: self) { viewModel in
            await viewModel.dismiss()
        }
    }
}

// MARK: - Private methods

private extension MobileRemoveWalletNotificationViewModel {
    func makePrimaryAction() -> Action {
        switch backupState {
        case .iCloudBackup:
            Action(
                title: Localization.hwRemoveWalletNotificationActionForget,
                handler: { [weak self] in
                    self?.removeHandler(deletesICloudBackup: false)
                }
            )
        case .seedBackup:
            Action(
                title: isICloudBackupFeatureAvailable
                    ? "View backup"
                    : Localization.hwRemoveWalletNotificationActionBackupView,
                handler: weakify(self, forFunction: MobileRemoveWalletNotificationViewModel.revealHandler)
            )
        case .noBackup:
            Action(
                title: Localization.hwRemoveWalletNotificationActionBackupGo,
                handler: weakify(self, forFunction: MobileRemoveWalletNotificationViewModel.backupHandler)
            )
        }
    }

    func makeSecondaryAction() -> Action {
        switch backupState {
        case .iCloudBackup:
            Action(
                title: "Forget and delete backup",
                handler: { [weak self] in
                    self?.removeHandler(deletesICloudBackup: true)
                }
            )
        case .seedBackup:
            Action(
                title: Localization.hwRemoveWalletNotificationActionForget,
                handler: { [weak self] in
                    self?.removeHandler(deletesICloudBackup: false)
                }
            )
        case .noBackup:
            Action(
                title: Localization.hwRemoveWalletNotificationActionForgetAnyway,
                handler: { [weak self] in
                    self?.removeHandler(deletesICloudBackup: false)
                }
            )
        }
    }

    func removeHandler(deletesICloudBackup: Bool) {
        removeManager.deletesICloudBackup = deletesICloudBackup
        runTask(in: self) { viewModel in
            await viewModel.openRemoveWallet()
        }
    }

    func backupHandler() {
        runTask(in: self) { viewModel in
            await viewModel.openSeedPhraseBackup()
        }
    }

    func revealHandler() {
        runTask(in: self) { viewModel in
            await viewModel.seedPhraseReveal()
        }
    }

    func seedPhraseReveal() async {
        do {
            let context = try await unlock()
            await openSeedPhraseReveal(context: context)
        } catch where error.isCancellationError {
            AppLogger.error("Unlock is canceled", error: error)
        } catch {
            AppLogger.error("Unlock failed:", error: error)
            await showAlert(error.alertBinder)
        }
    }

    @MainActor
    func showAlert(_ alert: AlertBinder) {
        alertPresenter.present(alert: alert)
    }
}

// MARK: - Unlocking

private extension MobileRemoveWalletNotificationViewModel {
    func unlock() async throws -> MobileWalletContext {
        let authUtil = MobileAuthUtil(
            userWalletId: userWalletModel.userWalletId,
            config: userWalletModel.config,
            biometricsProvider: CommonUserWalletBiometricsProvider()
        )
        let result = try await authUtil.unlock()

        switch result {
        case .successful(let context):
            return context

        case .canceled:
            throw CancellationError()

        case .userWalletNeedsToDelete:
            assertionFailure("Unexpected state: .userWalletNeedsToDelete should never happen.")
            throw CancellationError()
        }
    }
}

// MARK: - Analytics

private extension MobileRemoveWalletNotificationViewModel {
    func logForgetWalletRequestAnalytics() {
        let statusUtil = MobileBackupStatusUtil(userWalletModel: userWalletModel)

        Analytics.log(
            .walletSettingsForgetWalletRequest,
            params: [
                .source: .walletSettings,
                .backupCloud: statusUtil.hasICloudBackup ? .done : .incomplete,
                .backupManual: .affirmativeOrNegative(for: statusUtil.hasMnemonicBackup),
            ],
            contextParams: analyticsContextParams
        )
    }

    func logMobileBackupNeededAnalytics() {
        Analytics.log(
            .walletSettingsNoticeBackupFirst,
            params: [
                .source: .walletSettings,
                .action: .remove,
            ],
            contextParams: analyticsContextParams
        )
    }
}

// MARK: - Navigation

@MainActor
private extension MobileRemoveWalletNotificationViewModel {
    func openRemoveWallet() {
        coordinator?.openMobileRemoveWallet(removeManager: removeManager)
    }

    func openSeedPhraseBackup() {
        if isICloudBackupFeatureAvailable {
            coordinator?.openMobileBackupTypesFromRemoveWalletNotification(userWalletModel: userWalletModel)
        } else {
            let input = MobileOnboardingInput(flow: .seedPhraseBackup(
                userWalletModel: userWalletModel,
                source: .walletSettings(action: .remove)
            ))
            coordinator?.openMobileOnboardingFromRemoveWalletNotification(input: input)
        }
    }

    func openSeedPhraseReveal(context: MobileWalletContext) {
        let input = MobileOnboardingInput(flow: .seedPhraseReveal(context: context))
        coordinator?.openMobileOnboardingFromRemoveWalletNotification(input: input)
    }

    func dismiss() {
        coordinator?.dismissMobileRemoveWalletNotification()
    }
}

// MARK: - Types

extension MobileRemoveWalletNotificationViewModel {
    struct Action {
        let title: String
        let handler: () -> Void
    }
}

// MARK: - FloatingSheetContentViewModel

extension MobileRemoveWalletNotificationViewModel: FloatingSheetContentViewModel {}
