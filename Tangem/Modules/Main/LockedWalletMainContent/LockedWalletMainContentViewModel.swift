//
//  LockedWalletMainContentViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine

protocol MainLockedUserWalletDelegate: AnyObject {
    func openUnlockUserWalletBottomSheet(for userWalletModel: UserWalletModel)
}

class LockedWalletMainContentViewModel: ObservableObject {
    lazy var lockedNotificationInput: NotificationViewInput = {
        let factory = NotificationSettingsFactory()
        return .init(
            style: .tappable(action: { [weak self] _ in
                self?.openUnlockSheet()
            }),
            settings: factory.lockedWalletNotificationSettings()
        )
    }()

    lazy var singleWalletButtonsInfo: [ButtonWithIconInfo] = TokenActionType.allCases.map {
        ButtonWithIconInfo(
            title: $0.title,
            icon: $0.icon,
            action: {},
            disabled: true
        )
    }

    let isMultiWallet: Bool
    // [REDACTED_TODO_COMMENT]
    let isWithManageTokens: Bool

    private let userWalletModel: UserWalletModel
    private weak var lockedUserWalletDelegate: MainLockedUserWalletDelegate?

    init(
        userWalletModel: UserWalletModel,
        isMultiWallet: Bool,
        lockedUserWalletDelegate: MainLockedUserWalletDelegate?
    ) {
        self.userWalletModel = userWalletModel
        self.isMultiWallet = isMultiWallet
        self.lockedUserWalletDelegate = lockedUserWalletDelegate

        isWithManageTokens = userWalletModel.isMultiWallet
    }

    private func openUnlockSheet() {
        lockedUserWalletDelegate?.openUnlockUserWalletBottomSheet(for: userWalletModel)
    }
}
