//
//  MobileRemoveSocialWalletNotificationViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemLocalization
import TangemUIUtils
import TangemMobileWalletSdk
import protocol TangemUI.FloatingSheetContentViewModel

final class MobileRemoveSocialWalletNotificationViewModel: ObservableObject {
    @Injected(\.alertPresenter) private var alertPresenter: AlertPresenter

    let title = Localization.socialWalletDeleteTitle

    let description = Localization.socialWalletDeleteDescription(MobileBackupConstants.appleServiceName)

    lazy var deleteActionItem = makeDeleteActionItem()
    lazy var backupActionItem = makeBackupActionItem()

    private var analyticsContextParams: Analytics.ContextParams {
        .custom(userWalletModel.analyticsContextData)
    }

    private lazy var authUtil = MobileAuthUtil(
        userWalletId: userWalletModel.userWalletId,
        config: userWalletModel.config,
        biometricsProvider: CommonUserWalletBiometricsProvider()
    )

    private let userWalletModel: UserWalletModel
    private let removeManager: MobileRemoveSocialWalletManager

    private weak var coordinator: MobileRemoveSocialWalletNotificationRoutable?

    init(
        userWalletModel: UserWalletModel,
        removeManager: MobileRemoveSocialWalletManager,
        coordinator: MobileRemoveSocialWalletNotificationRoutable
    ) {
        self.userWalletModel = userWalletModel
        self.removeManager = removeManager
        self.coordinator = coordinator

        logDeleteWalletRequestAnalytics()
    }
}

// MARK: - Internal methods

extension MobileRemoveSocialWalletNotificationViewModel {
    func onCloseTap() {
        runTask(in: self) { viewModel in
            await viewModel.dismiss()
        }
    }
}

// MARK: - Private methods

private extension MobileRemoveSocialWalletNotificationViewModel {
    func makeDeleteActionItem() -> ActionItem {
        ActionItem(
            title: Localization.socialWalletDeleteAnyway,
            handler: weakify(self, forFunction: MobileRemoveSocialWalletNotificationViewModel.onDeleteTap)
        )
    }

    func makeBackupActionItem() -> ActionItem {
        if removeManager.hasSeedBackup {
            ActionItem(
                title: Localization.hwRemoveWalletNotificationActionBackupViewV2,
                handler: weakify(self, forFunction: MobileRemoveSocialWalletNotificationViewModel.onRevealTap)
            )
        } else {
            ActionItem(
                title: Localization.hwRemoveWalletNotificationActionBackupGo,
                handler: weakify(self, forFunction: MobileRemoveSocialWalletNotificationViewModel.onBackupTap)
            )
        }
    }

    func onDeleteTap() {
        runTask(in: self) { viewModel in
            await viewModel.openRemoveWallet()
        }
    }

    func onBackupTap() {
        runTask(in: self) { viewModel in
            await viewModel.seedPhraseBackup()
        }
    }

    func onRevealTap() {
        runTask(in: self) { viewModel in
            await viewModel.seedPhraseReveal()
        }
    }

    func seedPhraseBackup() async {
        await unlock { [weak self] context in
            await self?.openSeedPhraseBackup(context: context)
        }
    }

    func seedPhraseReveal() async {
        await unlock { [weak self] context in
            await self?.openSeedPhraseReveal(context: context)
        }
    }
}

// MARK: - Unlocking

private extension MobileRemoveSocialWalletNotificationViewModel {
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

private extension MobileRemoveSocialWalletNotificationViewModel {
    func logDeleteWalletRequestAnalytics() {
        Analytics.log(.walletSettingsDeleteWalletRequest, contextParams: analyticsContextParams)
    }
}

// MARK: - Alerts

@MainActor
private extension MobileRemoveSocialWalletNotificationViewModel {
    func showErrorAlert(_ error: Error) {
        alertPresenter.present(alert: error.alertBinder)
    }
}

// MARK: - Navigation

@MainActor
private extension MobileRemoveSocialWalletNotificationViewModel {
    func openRemoveWallet() {
        coordinator?.openMobileRemoveSocialWallet(removeManager: removeManager)
    }

    func openSeedPhraseBackup(context: MobileWalletContext) {
        let input = MobileOnboardingInput(flow: .seedPhraseBackup(
            userWalletModel: userWalletModel,
            source: .walletSettings,
            context: context
        ))
        coordinator?.openMobileOnboardingFromRemoveSocialWalletNotification(input: input)
    }

    func openSeedPhraseReveal(context: MobileWalletContext) {
        let input = MobileOnboardingInput(flow: .seedPhraseReveal(context: context))
        coordinator?.openMobileOnboardingFromRemoveSocialWalletNotification(input: input)
    }

    func dismiss() {
        coordinator?.dismissMobileRemoveSocialWalletNotification()
    }
}

// MARK: - Types

extension MobileRemoveSocialWalletNotificationViewModel {
    struct ActionItem {
        let title: String
        let handler: () -> Void
    }
}

// MARK: - FloatingSheetContentViewModel

extension MobileRemoveSocialWalletNotificationViewModel: FloatingSheetContentViewModel {}
