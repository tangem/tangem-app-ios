//
//  MainCoordinator+MainScreenDeeplinkRoutable.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension MainCoordinator: MainScreenDeeplinkRoutable {
    var isRootVisible: Bool {
        mainViewModel?.isRootVisible ?? false
    }

    var isShtorkaPresented: Bool {
        feedCoordinator?.shtorkaStateObject.isPresented ?? false
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
}
