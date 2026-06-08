//
//  AddFundsRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

@MainActor
protocol AddFundsRoutable: AnyObject {
    func addFundsRequestBuy(walletModel: any WalletModel, userWalletModel: any UserWalletModel)
    func addFundsRequestSwap(walletModel: any WalletModel, userWalletModel: any UserWalletModel)
    func addFundsRequestReceive(viewModel: ReceiveMainViewModel)
    func addFundsRequestGoToToken(walletModel: any WalletModel, userWalletModel: any UserWalletModel)
    func addFundsClose()
}
