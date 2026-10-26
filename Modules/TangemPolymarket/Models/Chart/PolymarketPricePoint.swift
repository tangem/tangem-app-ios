//
//  PolymarketPricePoint.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct PolymarketPricePoint: Hashable, Sendable {
    public let date: Date
    public let probability: Decimal

    public init(date: Date, probability: Decimal) {
        self.date = date
        self.probability = probability
    }
}
