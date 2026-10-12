//
//  PolymarketOrderQuoteState.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket

enum PolymarketOrderQuoteState: Equatable {
    case empty
    case loading
    case content(PolymarketOrderQuote)
    case unavailable(PolymarketQuoteUnavailability)
    case failed(PolymarketOrderQuoteFailure)

    var isAwaitingQuote: Bool {
        switch self {
        case .empty, .loading: true
        case .content, .unavailable, .failed: false
        }
    }

    var quote: PolymarketOrderQuote? {
        if case .content(let quote) = self { return quote }

        return nil
    }

    var isLive: Bool {
        quote?.isLive ?? false
    }

    init(quote: PolymarketOrderQuote) {
        switch quote.status {
        case .insufficientLiquidity: self = .unavailable(.insufficientLiquidity)
        case .marketClosed: self = .unavailable(.marketClosed)
        case .undefined: self = .unavailable(.undefined)
        case .full, .partial, .belowMinOrderSize, .belowMinOrderAmount: self = .content(quote)
        }
    }
}

// MARK: - Unavailability

enum PolymarketQuoteUnavailability: Equatable {
    case insufficientLiquidity
    case marketClosed
    case undefined
}

// MARK: - Failure

enum PolymarketOrderQuoteFailure: Equatable {
    case network
    case unknown

    init(error: Error) {
        if case PolymarketAPIError.connection = error {
            self = .network
        } else {
            self = .unknown
        }
    }
}
