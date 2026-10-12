//
//  PolymarketDTO+OrderQuote.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension PolymarketDTO {
    struct OrderQuoteRequestBody: Encodable {
        let marketId: String
        let assetId: String
        let side: String
        let amount: String
        let slippage: String
    }

    struct OrderQuoteResponse: Decodable {
        let status: String
        let side: String
        let shares: String
        let notional: String
        let expectedExecutionAmount: String
        let averagePrice: String
        let worstCasePrice: String
        let fees: OrderQuoteFees
        let total: String
        let builderCode: String
        let minOrderSize: String
        let minOrderAmount: String?
        let tickSize: String
        let live: Bool
    }

    struct OrderQuoteFees: Decodable {
        let market: String
        let builder: String
        let total: String
    }
}
