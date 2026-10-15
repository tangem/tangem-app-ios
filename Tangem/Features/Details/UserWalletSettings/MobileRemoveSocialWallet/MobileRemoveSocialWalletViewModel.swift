//
//  MobileRemoveSocialWalletViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemUIUtils
import TangemLocalization

final class MobileRemoveSocialWalletViewModel: ObservableObject {
    @Published var isBackupChecked = false
    @Published private(set) var isLoading = false
    @Published var confirmationDialog: ConfirmationDialogViewModel?

    @Injected(\.alertPresenter) private var alertPresenter: AlertPresenter

    let navigationTitle = Localization.socialWalletSettingsDeleteWallet
    let backupCheckTitle = Localization.socialWalletDeleteAttentionAcknowledge

    lazy var attentionItem = makeAttentionItem()
    lazy var actionItem = makeActionItem()

    var isActionEnabled: Bool {
        isBackupChecked && !isLoading
    }

    private let removeManager: MobileRemoveSocialWalletManager
    private weak var coordinator: MobileRemoveSocialWalletRoutable?

    init(
        removeManager: MobileRemoveSocialWalletManager,
        coordinator: MobileRemoveSocialWalletRoutable
    ) {
        self.removeManager = removeManager
        self.coordinator = coordinator

        logScreenOpenedAnalytics()
    }
}

// MARK: - Internal methods

extension MobileRemoveSocialWalletViewModel {
    func onBackTap() {
        guard !isLoading else { return }

        runTask(in: self) { viewModel in
            await viewModel.close()
        }
    }
}

// MARK: - Private methods

private extension MobileRemoveSocialWalletViewModel {
    func makeAttentionItem() -> AttentionItem {
        AttentionItem(
            title: Localization.commonAttention,
            subtitle: Localization.socialWalletDeleteAttentionDescription(MobileBackupConstants.appleServiceName)
        )
    }

    func makeActionItem() -> ActionItem {
        ActionItem(
            title: Localization.socialWalletSettingsDeleteWallet,
            handler: weakify(self, forFunction: MobileRemoveSocialWalletViewModel.onDeleteTap)
        )
    }

    func onDeleteTap() {
        let deleteButton = ConfirmationDialogViewModel.Button(
            title: Localization.commonDelete,
            role: .destructive,
            action: weakify(self, forFunction: MobileRemoveSocialWalletViewModel.onConfirmDeleteTap)
        )

        confirmationDialog = ConfirmationDialogViewModel(
            title: Localization.socialWalletDeleteConfirmationTitle(MobileBackupConstants.appleServiceName),
            buttons: [
                deleteButton,
                ConfirmationDialogViewModel.Button.cancel,
            ]
        )
    }

    func onConfirmDeleteTap() {
        runTask(in: self) { viewModel in
            await viewModel.removeWallet()
        }
    }

    func removeWallet() async {
        await setLoading(true)

        do {
            try await removeManager.removeWallet()
            await completed()
        } catch {
            AppLogger.error("Social wallet deletion failed:", error: error)
            await setLoading(false)
            await presentRemoveFailureAlert()
        }
    }

    @MainActor
    func setLoading(_ isLoading: Bool) {
        self.isLoading = isLoading
    }
}

// MARK: - Alerts

private extension MobileRemoveSocialWalletViewModel {
    @MainActor
    func presentRemoveFailureAlert() {
        let alert = AlertBuilder.makeAlertWithDefaultPrimaryButton(
            title: Localization.commonSomethingWentWrong,
            message: Localization.socialWalletDeleteErrorDescription,
            buttonText: Localization.commonOk
        )

        alertPresenter.present(alert: alert)
    }
}

// MARK: - Navigation

@MainActor
private extension MobileRemoveSocialWalletViewModel {
    func completed() {
        coordinator?.removeSocialWalletCompleted()
    }

    func close() {
        coordinator?.removeSocialWalletClose()
    }
}

// MARK: - Analytics

private extension MobileRemoveSocialWalletViewModel {
    func logScreenOpenedAnalytics() {
        Analytics.log(
            .walletSettingsDeleteWalletScreenOpened,
            contextParams: .custom(removeManager.analyticsContextData)
        )
    }
}

// MARK: - Types

extension MobileRemoveSocialWalletViewModel {
    struct AttentionItem {
        let title: String
        let subtitle: String
    }

    struct ActionItem {
        let title: String
        let handler: () -> Void
    }
}
