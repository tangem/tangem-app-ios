//
//  MobileRemoveWalletViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemAssets
import TangemUIUtils
import TangemLocalization

final class MobileRemoveWalletViewModel: ObservableObject {
    @Published var isBackupChecked = false
    @Published var isActionEnabled = false
    @Published var confirmationDialog: ConfirmationDialogViewModel?

    let navigationTitle = Localization.hwRemoveWalletNavTitle
    let backupInfo = Localization.hwRemoveWalletWarningAccess

    lazy var attentionItem: AttentionItem = makeAttentionItem()
    lazy var actionItem: ActionItem = makeActionItem()

    private let removeManager: MobileRemoveWalletManager
    private weak var delegate: MobileRemoveWalletDelegate?

    init(
        removeManager: MobileRemoveWalletManager,
        delegate: MobileRemoveWalletDelegate
    ) {
        self.removeManager = removeManager
        self.delegate = delegate
        bind()
    }
}

// MARK: - Private methods

private extension MobileRemoveWalletViewModel {
    func bind() {
        $isBackupChecked
            .assign(to: &$isActionEnabled)
    }

    func makeAttentionItem() -> AttentionItem {
        AttentionItem(
            icon: Assets.attentionRed,
            title: Localization.commonAttention,
            subtitle: Localization.hwRemoveWalletAttentionDescription
        )
    }

    func makeActionItem() -> ActionItem {
        ActionItem(
            title: Localization.hwRemoveWalletActionForgetTitle,
            action: weakify(self, forFunction: MobileRemoveWalletViewModel.onForgetTap)
        )
    }

    func onForgetTap() {
        let forgetButton = ConfirmationDialogViewModel.Button(
            title: Localization.commonForget,
            role: .destructive,
            action: weakify(self, forFunction: MobileRemoveWalletViewModel.onConfirmForgetTap)
        )

        confirmationDialog = ConfirmationDialogViewModel(
            title: Localization.hwRemoveWalletConfirmationTitle,
            buttons: [
                forgetButton,
                ConfirmationDialogViewModel.Button.cancel,
            ]
        )
    }

    func onConfirmForgetTap() {
        removeManager.removeWallet()
        delegate?.didRemoveMobileWallet()
    }
}

// MARK: - Types

extension MobileRemoveWalletViewModel {
    struct AttentionItem {
        let icon: ImageType
        let title: String
        let subtitle: String
    }

    struct ActionItem {
        let title: String
        let action: () -> Void
    }
}
