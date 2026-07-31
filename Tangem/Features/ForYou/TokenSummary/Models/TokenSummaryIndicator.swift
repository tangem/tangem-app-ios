//
//  TokenSummaryIndicator.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Domain representation of a single coin-indicator reading, decoupled from the transport DTO.
struct TokenSummaryIndicator {
    let kind: Kind
    let timeframe: Timeframe?
    let value: Decimal?
    let signal: Signal
    let subLabel: String?
    let updatedAt: Date?
}

extension TokenSummaryIndicator {
    enum Kind: Hashable {
        case rsi
        case macd
        case maCross
        case galaxyScore
        case sentiment
        case unknown
    }

    /// A `nil` timeframe on the reading marks a timeframe-agnostic indicator; `.unknown` is a value the contract
    /// reports that this build doesn't recognize.
    enum Timeframe: Equatable {
        case day
        case week
        case month
        case unknown
    }

    /// Directional signals drive the gauge; `.unavailable` collapses every non-directional case and is left out of it.
    enum Signal: Equatable {
        case bullish
        case bearish
        case neutral
        case unavailable
    }
}
