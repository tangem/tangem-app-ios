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
        let factory = NotificationsFactory()
        let event: WarningEvent = .walletLocked
        return .init(
            style: .tappable { [weak self] _ in
                self?.onLockedWalletNotificationTap()
            },
            severity: event.severity,
            settings: .init(event: event, dismissAction: nil)
        )
    }()

    lazy var singleWalletButtonsInfo: [ButtonWithIconInfo] = TokenActionListBuilder()
        .buildActionsForLockedSingleWallet()
        .map {
            ButtonWithIconInfo(
                title: $0.title,
                icon: $0.icon,
                action: {},
                disabled: true
            )
        }

    var footerViewModel: MainFooterViewModel? {
        guard canManageTokens else { return nil }

        return MainFooterViewModel(
            isButtonDisabled: true,
            buttonTitle: Localization.mainManageTokens,
            buttonAction: {}
        )
    }

    let isMultiWallet: Bool

    private let userWalletModel: UserWalletModel
    private let contextData: AnalyticsContextData?

    private var canManageTokens: Bool { userWalletModel.config.hasFeature(.multiCurrency) }
    private weak var lockedUserWalletDelegate: MainLockedUserWalletDelegate?

    init(
        userWalletModel: UserWalletModel,
        isMultiWallet: Bool,
        lockedUserWalletDelegate: MainLockedUserWalletDelegate?
    ) {
        self.userWalletModel = userWalletModel
        self.isMultiWallet = isMultiWallet
        self.lockedUserWalletDelegate = lockedUserWalletDelegate

        contextData = userWalletModel.getAnalyticsContextData()
        Analytics.log(event: .mainNoticeWalletUnlock, params: contextData?.analyticsParams ?? [:])
    }

    private func onLockedWalletNotificationTap() {
        Analytics.log(event: .mainNoticeWalletUnlockTapped, params: contextData?.analyticsParams ?? [:])
        openUnlockSheet()
    }

    private func openUnlockSheet() {
        lockedUserWalletDelegate?.openUnlockUserWalletBottomSheet(for: userWalletModel)
    }
}
