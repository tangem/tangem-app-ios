//
//  ExpectedQuote.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct ExpectedQuote {
    public let provider: ExpressProvider
    public let state: State
    public let isBest: Bool

    public var quote: ExpressQuote? {
        switch state {
        case .quote(let expressQuote):
            return expressQuote
        case .error, .notAvailable, .tooSmallAmount:
            return nil
        }
    }

    public var error: Error? {
        switch state {
        case .error(let error):
            return error
        case .quote, .notAvailable, .tooSmallAmount:
            return nil
        }
    }

    public var rate: Decimal {
        if let quote, !quote.fromAmount.isZero {
            return quote.expectAmount / quote.fromAmount
        }

        return 0
    }

    public var priority: Priority {
        if isBest {
            return .highest
        }

        switch state {
        case .quote:
            return .high
        case .tooSmallAmount:
            return .medium
        case .error, .notAvailable:
            return .lowest
        }
    }

    init(provider: ExpressProvider, state: State, isBest: Bool) {
        self.provider = provider
        self.isBest = isBest
        self.state = state
    }
}

public extension ExpectedQuote {
    enum Priority: Int, Comparable {
        case lowest
        case low
        case medium
        case high
        case highest

        public static func < (lhs: ExpectedQuote.Priority, rhs: ExpectedQuote.Priority) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    enum State {
        case quote(ExpressQuote)
        case error(Error)
        case notAvailable
        case tooSmallAmount(minAmount: Decimal)

        public var quote: ExpressQuote? {
            switch self {
            case .quote(let expressQuote):
                return expressQuote
            case .error, .notAvailable, .tooSmallAmount:
                return nil
            }
        }
    }
}
