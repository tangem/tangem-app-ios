//
//  PolymarketPriceHistoryQuery.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct PolymarketPriceHistoryQuery: Hashable, Sendable {
    public let window: Window
    public let fidelityMinutes: Int

    init(window: Window, fidelityMinutes: Int) {
        self.window = window
        self.fidelityMinutes = fidelityMinutes
    }
}

// MARK: - Window

public extension PolymarketPriceHistoryQuery {
    enum Window: Hashable, Sendable {
        case interval(PolymarketPriceInterval)
        case range(start: Date, end: Date?)
    }
}

// MARK: - Factory

extension PolymarketPriceHistoryQuery {
    static func interval(_ interval: PolymarketPriceInterval, fidelityMinutes: Int) -> Self {
        Self(window: .interval(interval), fidelityMinutes: fidelityMinutes)
    }

    static func range(start: Date, end: Date?, fidelityMinutes: Int) -> Self {
        Self(window: .range(start: start, end: end), fidelityMinutes: fidelityMinutes)
    }
}
