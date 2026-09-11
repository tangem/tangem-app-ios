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
            Localization.hwRemoveWalletCloudBackupTitle
        case .seedBackup, .noBackup:
            isICloudBackupFeatureAvailable
                ? Localization.hwRemoveWalletNotificationTitleV2
                : Localization.hwRemoveWalletNotificationTitle
        }
    }

    var description: String {
        switch backupState {
        case .iCloudBackup:
            Localization.hwRemoveWalletCloudBackupDescription(MobileBackupConstants.iCloudServiceName)
        case .seedBackup:
            isICloudBackupFeatureAvailable
                ? Localization.hwRemoveWalletNotificationDescriptionHasBackupV2
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

    private lazy var authUtil = MobileAuthUtil(
        userWalletId: userWalletModel.userWalletId,
        config: userWalletModel.config,
        biometricsProvider: CommonUserWalletBiometricsProvider()
    )

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
                    ? Localization.hwRemoveWalletNotificationActionBackupViewV2
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
                title: Localization.hwRemoveWalletForgetAndDeleteBackup,
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
            await viewModel.handleSeedPhraseBackup()
        }
    }

    func handleSeedPhraseBackup() async {
        if isICloudBackupFeatureAvailable {
            await openMobileBackupTypes()
        } else {
            await unlock { [weak self] context in
                await self?.openSeedPhraseBackup(context: context)
            }
        }
    }

    func revealHandler() {
        runTask(in: self) { viewModel in
            await viewModel.seedPhraseReveal()
        }
    }

    func seedPhraseReveal() async {
        await unlock { [weak self] context in
            await self?.openSeedPhraseReveal(context: context)
        }
    }
}

// MARK: - Unlocking

private extension MobileRemoveWalletNotificationViewModel {
    func unlock(handler: @escaping (MobileWalletContext) async -> Void) async {
        switch await unlock() {
        case .successful(let context):
            await handler(context)
        case .failed(let error):
            AppLogger.error("Unlock failed:", error: error)
            await showErrorAlert(error)
        case .canceled:
            break
        }
    }

    func unlock() async -> UnlockResult {
        do {
            let result = try await authUtil.unlock()

            switch result {
            case .successful(let context):
                return .successful(context: context)

            case .canceled:
                return .canceled

            case .userWalletNeedsToDelete:
                assertionFailure("Unexpected state: .userWalletNeedsToDelete should never happen.")
                return .canceled
            }

        } catch {
            return .failed(error: error)
        }
    }

    enum UnlockResult {
        case successful(context: MobileWalletContext)
        case canceled
        case failed(error: Error)
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

// MARK: - Alerts

@MainActor
private extension MobileRemoveWalletNotificationViewModel {
    func showErrorAlert(_ error: Error) {
        let alert = error.alertBinder
        showAlert(alert)
    }

    func showAlert(_ alert: AlertBinder) {
        alertPresenter.present(alert: alert)
    }
}

// MARK: - Navigation

@MainActor
private extension MobileRemoveWalletNotificationViewModel {
    func openRemoveWallet() {
        coordinator?.openMobileRemoveWallet(removeManager: removeManager)
    }

    func openMobileBackupTypes() {
        coordinator?.openMobileBackupTypesFromRemoveWalletNotification(userWalletModel: userWalletModel)
    }

    func openSeedPhraseBackup(context: MobileWalletContext) {
        let input = MobileOnboardingInput(flow: .seedPhraseBackup(
            userWalletModel: userWalletModel,
            source: .walletSettings(action: .remove),
            context: context
        ))
        coordinator?.openMobileOnboardingFromRemoveWalletNotification(input: input)
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
