//
//  PolymarketOrderQuote.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct PolymarketOrderQuote: Hashable, Sendable {
    public let status: PolymarketQuoteStatus
    public let side: PolymarketOrderSide

    public let shares: Decimal
    public let notional: Decimal
    public let expectedExecutionAmount: Decimal

    public let averagePrice: Decimal
    public let worstCasePrice: Decimal

    public let fees: PolymarketOrderFees
    public let total: Decimal

    public let builderCode: String

    public let minOrderSize: Decimal
    public let minOrderAmount: Decimal?

    public let tickSize: Decimal

    public let isLive: Bool

    public let version: PolymarketMarketVersion
    public let exchange: String?
    public let signingDomainVersion: String?

    public init(
        status: PolymarketQuoteStatus,
        side: PolymarketOrderSide,
        shares: Decimal,
        notional: Decimal,
        expectedExecutionAmount: Decimal,
        averagePrice: Decimal,
        worstCasePrice: Decimal,
        fees: PolymarketOrderFees,
        total: Decimal,
        builderCode: String,
        minOrderSize: Decimal,
        minOrderAmount: Decimal?,
        tickSize: Decimal,
        isLive: Bool,
        version: PolymarketMarketVersion,
        exchange: String?,
        signingDomainVersion: String?
    ) {
        self.status = status
        self.side = side
        self.shares = shares
        self.notional = notional
        self.expectedExecutionAmount = expectedExecutionAmount
        self.averagePrice = averagePrice
        self.worstCasePrice = worstCasePrice
        self.fees = fees
        self.total = total
        self.builderCode = builderCode
        self.minOrderSize = minOrderSize
        self.minOrderAmount = minOrderAmount
        self.tickSize = tickSize
        self.isLive = isLive
        self.version = version
        self.exchange = exchange
        self.signingDomainVersion = signingDomainVersion
    }
}

// MARK: - Fees

public struct PolymarketOrderFees: Hashable, Sendable {
    public let market: Decimal
    public let builder: Decimal
    public let total: Decimal

    public init(market: Decimal, builder: Decimal, total: Decimal) {
        self.market = market
        self.builder = builder
        self.total = total
    }
}
