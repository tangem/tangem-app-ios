//
//  PolymarketEvent.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct PolymarketEvent: Hashable, Sendable {
    public let id: String

    public let slug: String

    public let title: String
    public let description: String?

    public let rulesURL: URL?

    public let imageURL: URL?
    public let iconURL: URL?

    public let status: PolymarketEventStatus
    public let startDate: Date?
    public let endDate: Date?

    public let volume: Decimal?
    public let volume24h: Decimal?
    public let liquidity: Decimal?

    public let totalMarketsCount: Int

    public let isNegRisk: Bool
    public let displayMode: PolymarketDisplayMode

    public let markets: [PolymarketMarket]

    public var hasMoreMarkets: Bool {
        markets.count < totalMarketsCount
    }

    public init(
        id: String,
        slug: String,
        title: String,
        description: String?,
        rulesURL: URL?,
        imageURL: URL?,
        iconURL: URL?,
        status: PolymarketEventStatus,
        startDate: Date?,
        endDate: Date?,
        volume: Decimal?,
        volume24h: Decimal?,
        liquidity: Decimal?,
        totalMarketsCount: Int,
        isNegRisk: Bool,
        displayMode: PolymarketDisplayMode,
        markets: [PolymarketMarket]
    ) {
        self.id = id
        self.slug = slug
        self.title = title
        self.description = description
        self.rulesURL = rulesURL
        self.imageURL = imageURL
        self.iconURL = iconURL
        self.status = status
        self.startDate = startDate
        self.endDate = endDate
        self.volume = volume
        self.volume24h = volume24h
        self.liquidity = liquidity
        self.totalMarketsCount = totalMarketsCount
        self.isNegRisk = isNegRisk
        self.displayMode = displayMode
        self.markets = markets
    }
}
