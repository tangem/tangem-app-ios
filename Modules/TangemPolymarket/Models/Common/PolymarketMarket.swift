//
//  PolymarketMarket.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct PolymarketMarket: Hashable, Sendable {
    public let id: String

    public let title: String

    public let groupItemTitle: String?

    public let imageURL: URL?
    public let iconURL: URL?

    public let status: PolymarketEventStatus
    public let isNegRisk: Bool

    public let startDate: Date?
    public let endDate: Date?

    public let volume: Decimal?
    public let volume24h: Decimal?
    public let liquidity: Decimal?

    public let outcomes: [PolymarketOutcome]

    public init(
        id: String,
        title: String,
        groupItemTitle: String?,
        imageURL: URL?,
        iconURL: URL?,
        status: PolymarketEventStatus,
        isNegRisk: Bool,
        startDate: Date?,
        endDate: Date?,
        volume: Decimal?,
        volume24h: Decimal?,
        liquidity: Decimal?,
        outcomes: [PolymarketOutcome]
    ) {
        self.id = id
        self.title = title
        self.groupItemTitle = groupItemTitle
        self.imageURL = imageURL
        self.iconURL = iconURL
        self.status = status
        self.isNegRisk = isNegRisk
        self.startDate = startDate
        self.endDate = endDate
        self.volume = volume
        self.volume24h = volume24h
        self.liquidity = liquidity
        self.outcomes = outcomes
    }
}
