//
//  LockedWalletMainContentViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine

protocol LockedWalletDelegate: AnyObject {
    func openUnlockSheet(for userWalletModel: UserWalletModel)
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

    var isMultiWallet: Bool {
        userWalletModel.isMultiWallet
    }

    private let userWalletModel: UserWalletModel
    private weak var lockedWalletDelegate: LockedWalletDelegate?

    init(userWalletModel: UserWalletModel, lockedWalletDelegate: LockedWalletDelegate?) {
        self.userWalletModel = userWalletModel
        self.lockedWalletDelegate = lockedWalletDelegate
    }

    private func openUnlockSheet() {
        lockedWalletDelegate?.openUnlockSheet(for: userWalletModel)
    }
}
