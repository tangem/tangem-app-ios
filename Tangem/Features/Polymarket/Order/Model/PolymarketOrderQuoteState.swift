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
    case resuming(hiddenFailuresLeft: Int)
    case content(PolymarketOrderQuote)
    case unavailable(PolymarketQuoteUnavailability, quote: PolymarketOrderQuote?)
    case failed(PolymarketOrderQuoteFailure)

    var isAwaitingQuote: Bool {
        switch self {
        case .empty, .loading, .resuming: true
        case .content, .unavailable, .failed: false
        }
    }

    var isResuming: Bool {
        if case .resuming = self { return true }

        return false
    }

    var quote: PolymarketOrderQuote? {
        if case .content(let quote) = self { return quote }

        return nil
    }

    var expectedExecutionAmount: Decimal? {
        switch self {
        case .content(let quote), .unavailable(.insufficientLiquidity, .some(let quote)):
            quote.expectedExecutionAmount
        case .empty, .loading, .resuming, .failed, .unavailable:
            nil
        }
    }

    var isFailed: Bool {
        if case .failed = self { return true }

        return false
    }

    var isLive: Bool {
        quote?.isLive ?? false
    }

    init(quote: PolymarketOrderQuote) {
        switch quote.status {
        case .insufficientLiquidity: self = .unavailable(.insufficientLiquidity, quote: quote)
        case .marketClosed: self = .unavailable(.marketClosed, quote: quote)
        case .undefined: self = .unavailable(.undefined, quote: quote)
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

// MARK: - Book price

enum PolymarketBookPriceFailure: Equatable {
    case marketClosed
    case unreadable

    init?(error: Error) {
        guard case PolymarketAPIError.http(let statusCode, _) = error else { return nil }

        switch statusCode {
        case Constants.noOrderBookStatusCode: self = .marketClosed
        case Constants.invalidTokenStatusCode: self = .unreadable
        default: return nil
        }
    }

    private enum Constants {
        static let noOrderBookStatusCode = 404
        static let invalidTokenStatusCode = 400
    }
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
