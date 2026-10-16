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
    public let conditionId: String?
    public let version: PolymarketMarketVersion

    public let title: String

    public let groupItemTitle: String?

    public let imageURL: URL?
    public let iconURL: URL?

    public let status: PolymarketEventStatus
    public let isNegRisk: Bool
    public let isAcceptingOrders: Bool

    public let startDate: Date?
    public let endDate: Date?

    public let volume: Decimal?
    public let volume24h: Decimal?
    public let liquidity: Decimal?

    public let orderIndex: Int?

    public let outcomes: [PolymarketOutcome]

    public init(
        id: String,
        conditionId: String?,
        version: PolymarketMarketVersion = .v1,
        title: String,
        groupItemTitle: String?,
        imageURL: URL?,
        iconURL: URL?,
        status: PolymarketEventStatus,
        isNegRisk: Bool,
        isAcceptingOrders: Bool,
        startDate: Date?,
        endDate: Date?,
        volume: Decimal?,
        volume24h: Decimal?,
        liquidity: Decimal?,
        orderIndex: Int?,
        outcomes: [PolymarketOutcome]
    ) {
        self.id = id
        self.conditionId = conditionId
        self.version = version
        self.title = title
        self.groupItemTitle = groupItemTitle
        self.imageURL = imageURL
        self.iconURL = iconURL
        self.status = status
        self.isNegRisk = isNegRisk
        self.isAcceptingOrders = isAcceptingOrders
        self.startDate = startDate
        self.endDate = endDate
        self.volume = volume
        self.volume24h = volume24h
        self.liquidity = liquidity
        self.orderIndex = orderIndex
        self.outcomes = outcomes
    }
}
