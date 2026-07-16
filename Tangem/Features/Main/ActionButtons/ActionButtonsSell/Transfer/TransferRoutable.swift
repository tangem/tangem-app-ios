//
//  TransferRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

@MainActor
protocol TransferRoutable: AnyObject {
    func transferRequestSell(walletModel: any WalletModel, userWalletInfo: UserWalletInfo)
    func transferRequestSwap(walletModel: any WalletModel, userWalletInfo: UserWalletInfo)
    func transferRequestSend(walletModel: any WalletModel, userWalletInfo: UserWalletInfo)
    func transferRequestSwapAndSend(walletModel: any WalletModel, userWalletInfo: UserWalletInfo)
    func transferClose()
}
