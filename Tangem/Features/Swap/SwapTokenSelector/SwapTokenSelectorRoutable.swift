//
//  SwapTokenSelectorRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemAccounts

protocol SwapTokenSelectorRoutable: AnyObject {
    func closeSwapTokenSelector()

    /// Opens the add-token flow for an external token selected from search results
    func openAddTokenFlowForExpress(
        coinId: String,
        coinName: String,
        coinSymbol: String,
        swapDirection: SwapTokenSelectorViewModel.SwapDirection,
        userWalletInfo: UserWalletInfo,
        completion: @escaping (TokenItem, any CryptoAccountModel) -> Void
    )
}
