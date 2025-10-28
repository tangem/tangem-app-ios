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

final class MobileRemoveWalletViewModel: ObservableObject {
    @Published var isRemoveChecked = false
    @Published var isBackupChecked = false
    @Published var isActionEnabled = false
    @Published var confirmationDialog: ConfirmationDialogViewModel?

    // [REDACTED_TODO_COMMENT]
    let navigationTitle = "Forget wallet"
    let removeInfo = "I understand that removing my wallet does not delete it—but simply removes it from my device."
    let backupInfo = "I understand that if I haven't backed up my wallet before removing it, I may lose access to it."

    lazy var attentionItem: AttentionItem = makeAttentionItem()
    lazy var actionItem: ActionItem = makeActionItem()

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    private let userWalletId: UserWalletId
    private weak var delegate: MobileRemoveWalletDelegate?

    init(userWalletId: UserWalletId, delegate: MobileRemoveWalletDelegate?) {
        self.userWalletId = userWalletId
        self.delegate = delegate
        bind()
    }
}

// MARK: - Private methods

private extension MobileRemoveWalletViewModel {
    func bind() {
        $isRemoveChecked
            .combineLatest($isBackupChecked)
            .map { isRemoveChecked, isBackupChecked in
                isRemoveChecked && isBackupChecked
            }
            .assign(to: &$isActionEnabled)
    }

    // [REDACTED_TODO_COMMENT]
    func makeAttentionItem() -> AttentionItem {
        AttentionItem(
            icon: Assets.attentionRed,
            title: "Attention",
            subtitle: "This wallet will be permanently removed from your device"
        )
    }

    func makeActionItem() -> ActionItem {
        ActionItem(
            title: "Forget wallet",
            action: weakify(self, forFunction: MobileRemoveWalletViewModel.onForgetTap)
        )
    }

    func onForgetTap() {
        let forgetButton = ConfirmationDialogViewModel.Button(
            title: "Forget",
            role: .destructive,
            action: weakify(self, forFunction: MobileRemoveWalletViewModel.onConfirmForgetTap)
        )

        confirmationDialog = ConfirmationDialogViewModel(
            title: "Are you sure you want to do this?",
            buttons: [
                forgetButton,
                ConfirmationDialogViewModel.Button.cancel,
            ]
        )
    }

    func onConfirmForgetTap() {
        userWalletRepository.delete(userWalletId: userWalletId)
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
