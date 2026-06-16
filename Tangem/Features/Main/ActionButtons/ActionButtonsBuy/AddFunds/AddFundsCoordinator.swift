//
//  AddFundsCoordinator.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol AddFundsCoordinator: AnyObject {
    func openBuy(userWalletInfo: UserWalletInfo, walletModel: any WalletModel)
    func openSwap(userWalletInfo: UserWalletInfo, walletModel: any WalletModel)
    func openReceive(walletModel: any WalletModel)
    func openTokenDetails(userWalletInfo: UserWalletInfo, walletModel: any WalletModel)
    func closeAddFunds()
}
