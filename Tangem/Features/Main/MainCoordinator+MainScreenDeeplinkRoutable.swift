//
//  MainCoordinator+MainScreenDeeplinkRoutable.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

extension MainCoordinator: MainScreenDeeplinkRoutable {
    var isRootVisible: Bool {
        mainViewModel?.isRootVisible ?? false
    }

    func openFeed(selection: FeedSelection) {
        shtorka?.open(selection: selection)
    }

    func openBuy(userWalletModel: any UserWalletModel) {
        openBuy(
            userWalletModels: [userWalletModel],
            preferredWalletId: ActionButtonsBuyPreselection.userWalletId(for: userWalletModel)
        )
    }

    func openSell(userWalletModel: any UserWalletModel) {
        openSell(userWalletModel: userWalletModel, tokenSelectorViewModel: .deeplinkSell())
    }

    func selectWallet(userWalletId: UserWalletId) {
        mainViewModel?.selectPage(userWalletId: userWalletId)
    }

    func expandAccount(_ jointAccount: any JointAccountModel, userWalletId: UserWalletId) {
        @Injected(\.expandableAccountItemStateStorageProvider)
        var expandableAccountItemStateStorageProvider: ExpandableAccountItemStateStorageProvider

        expandableAccountItemStateStorageProvider
            .makeStateStorage(for: userWalletId)
            .setIsExpanded(true, for: jointAccount)
    }
}
