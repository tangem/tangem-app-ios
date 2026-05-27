//
//  ExpressFlowTypeResolver.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Determines whether a quote should follow the CEX or DEX execution flow.
/// Resolution precedence:
/// 1. `txType` from the quote response (if present)
/// 2. Provider's static type for known types (`.cex` → `.send`, `.dex`/`.dexBridge` → `.swap`)
/// 3. Heuristic fallback based on `allowanceContract` presence
protocol ExpressFlowTypeResolver {
    func resolveFlowType(quote: ExpressQuote, provider: ExpressProvider) -> ExpressTransactionType
}

struct CommonExpressFlowTypeResolver: ExpressFlowTypeResolver {
    func resolveFlowType(quote: ExpressQuote, provider: ExpressProvider) -> ExpressTransactionType {
        if let txType = quote.txType {
            return txType
        }

        switch provider.type {
        case .cex:
            return .send
        case .dex, .dexBridge:
            return .swap
        case .onramp, .unknown:
            return quote.allowanceContract != nil ? .swap : .send
        }
    }
}
