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
    func openAddTokenFlowForExpress(inputData: ExpressAddTokenInputData)

    /// Called when a token is added via the add-token flow
    func onTokenAdded(item: AccountsAwareTokenSelectorItem)
}

struct ExpressAddTokenInputData {
    let coinId: String
    let coinName: String
    let coinSymbol: String
    let networks: [NetworkModel]
    let swapDirection: SwapTokenSelectorViewModel.SwapDirection
}
