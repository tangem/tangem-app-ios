//
//  SwapMarketsTokenAdditionRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemAccounts

/// Handler protocol for market token addition flow in swap context.
/// Separates token addition orchestration from navigation concerns.
protocol SwapMarketsTokenAdditionRoutable: AnyObject {
    /// Request to initiate the add-token flow for an external token selected from markets.
    /// - Parameter inputData: The market token data needed to start the add-token flow
    @MainActor
    func requestAddToken(inputData: ExpressAddTokenInputData)

    /// Called when a token has been successfully added via the add-token flow.
    /// - Parameter item: The newly added token item that should be selected
    @MainActor
    func didAddMarketToken(item: AccountsAwareTokenSelectorItem)
}

struct ExpressAddTokenInputData {
    let coinId: String
    let coinName: String
    let coinSymbol: String
    let networks: [NetworkModel]
}
