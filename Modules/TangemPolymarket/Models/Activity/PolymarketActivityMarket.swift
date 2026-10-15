//
//  PolymarketActivityMarket.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct PolymarketActivityMarket: Hashable, Sendable {
    public let conditionId: String
    public let outcomeIndex: Int
    public let shares: Decimal
    public let outcome: String?
    public let marketId: String?
    public let slug: String?
    public let title: String?
    public let iconURL: URL?
    public let imageURL: URL?
    public let endDate: Date?
    public let isNegRisk: Bool
    public let event: PolymarketActivityEvent?

    public init(
        conditionId: String,
        outcomeIndex: Int,
        shares: Decimal,
        outcome: String?,
        marketId: String?,
        slug: String?,
        title: String?,
        iconURL: URL?,
        imageURL: URL?,
        endDate: Date?,
        isNegRisk: Bool,
        event: PolymarketActivityEvent?
    ) {
        self.conditionId = conditionId
        self.outcomeIndex = outcomeIndex
        self.shares = shares
        self.outcome = outcome
        self.marketId = marketId
        self.slug = slug
        self.title = title
        self.iconURL = iconURL
        self.imageURL = imageURL
        self.endDate = endDate
        self.isNegRisk = isNegRisk
        self.event = event
    }
}

// MARK: - Event

public struct PolymarketActivityEvent: Hashable, Sendable {
    public let eventId: String
    public let slug: String?
    public let title: String
    public let iconURL: URL?
    public let imageURL: URL?
    public let endDate: Date?

    public init(
        eventId: String,
        slug: String?,
        title: String,
        iconURL: URL?,
        imageURL: URL?,
        endDate: Date?
    ) {
        self.eventId = eventId
        self.slug = slug
        self.title = title
        self.iconURL = iconURL
        self.imageURL = imageURL
        self.endDate = endDate
    }
}
