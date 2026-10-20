//
//  PolymarketClosedPosition.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct PolymarketClosedPosition: Hashable, Sendable, Identifiable {
    public let conditionId: String
    public let assetId: String

    public let title: String
    public let slug: String?
    public let iconURL: URL?

    public let closedAt: Date?

    public let outcome: String
    public let outcomeIndex: Int?

    public let avgPrice: Decimal
    public let curPrice: Decimal
    public let totalBought: Decimal
    public let realizedPnl: Decimal

    public let status: PolymarketClosedPositionStatus

    public var id: String { "\(conditionId)/\(assetId)" }

    public init(
        conditionId: String,
        assetId: String,
        title: String,
        slug: String?,
        iconURL: URL?,
        closedAt: Date?,
        outcome: String,
        outcomeIndex: Int?,
        avgPrice: Decimal,
        curPrice: Decimal,
        totalBought: Decimal,
        realizedPnl: Decimal,
        status: PolymarketClosedPositionStatus
    ) {
        self.conditionId = conditionId
        self.assetId = assetId
        self.title = title
        self.slug = slug
        self.iconURL = iconURL
        self.closedAt = closedAt
        self.outcome = outcome
        self.outcomeIndex = outcomeIndex
        self.avgPrice = avgPrice
        self.curPrice = curPrice
        self.totalBought = totalBought
        self.realizedPnl = realizedPnl
        self.status = status
    }
}

// MARK: - Status

public enum PolymarketClosedPositionStatus: String, Hashable, Sendable, CaseIterable {
    case closed = "CLOSED"
    case won = "WON"
    case lost = "LOST"
    case split = "SPLIT"

    case unknown
}

// MARK: - Page

public struct PolymarketClosedPositionsPage: Hashable, Sendable {
    public let positions: [PolymarketClosedPosition]
    public let receivedCount: Int
    public let nextCursor: String?

    public var hasNext: Bool {
        nextCursor != nil
    }

    public init(positions: [PolymarketClosedPosition], receivedCount: Int, nextCursor: String?) {
        self.positions = positions
        self.receivedCount = receivedCount
        self.nextCursor = nextCursor
    }
}
