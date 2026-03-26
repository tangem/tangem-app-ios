//
//  ExpressFlowTypeResolver.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Determines whether a quote should follow the CEX or DEX execution flow.
/// Used by `CombinedExpressProviderManager` for hybrid providers whose flow type
/// is not known until after the `/exchange-quote` response.
protocol ExpressFlowTypeResolver {
    func resolveFlowType(quote: ExpressQuote, provider: ExpressProvider) -> ExpressTransactionType
}

/// Placeholder resolver using heuristics. Will be replaced when the backend
/// adds an explicit field to the quote response indicating the resolved flow type.
struct DefaultExpressFlowTypeResolver: ExpressFlowTypeResolver {
    func resolveFlowType(quote: ExpressQuote, provider: ExpressProvider) -> ExpressTransactionType {
        // Heuristic: allowanceContract presence implies DEX (on-chain swap).
        // Native coin swaps on DEX may not have allowanceContract, but this is
        // the best signal available until the backend provides an explicit field.
        quote.allowanceContract != nil ? .swap : .send
    }
}
