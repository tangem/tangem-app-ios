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
    @MainActor
    func openAddTokenFlowForExpress(
        inputData: ExpressAddTokenInputData,
        completion: @escaping (TokenItem, UserWalletInfo, any CryptoAccountModel) -> Void
    )
}

struct ExpressAddTokenInputData {
    let coinId: String
    let coinName: String
    let coinSymbol: String
    let networks: [NetworkModel]
    let swapDirection: SwapTokenSelectorViewModel.SwapDirection
}
