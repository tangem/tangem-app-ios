//
//  PolymarketPosition.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct PolymarketPosition: Hashable, Sendable, Identifiable {
    public let conditionId: String
    public let assetId: String

    public let marketId: String?
    public let eventId: String?
    public let eventTitle: String?

    public let title: String
    public let iconURL: URL?
    public let endDate: Date?

    public let outcome: String

    public let size: Decimal
    public let avgPrice: Decimal
    public let curPrice: Decimal
    public let initialValue: Decimal
    public let currentValue: Decimal
    public let cashPnl: Decimal
    public let pnlRatio: Decimal
    public let realizedPnl: Decimal

    public let isRedeemable: Bool
    public let isNegRisk: Bool
    public let isAcceptingOrders: Bool
    public let isLive: Bool

    public let resolutionStatus: PolymarketResolutionStatus
    public let settlement: PolymarketPositionSettlement?

    public var id: String { "\(conditionId)/\(assetId)" }

    public init(
        conditionId: String,
        assetId: String,
        marketId: String?,
        eventId: String?,
        eventTitle: String?,
        title: String,
        iconURL: URL?,
        endDate: Date?,
        outcome: String,
        size: Decimal,
        avgPrice: Decimal,
        curPrice: Decimal,
        initialValue: Decimal,
        currentValue: Decimal,
        cashPnl: Decimal,
        pnlRatio: Decimal,
        realizedPnl: Decimal,
        isRedeemable: Bool,
        isNegRisk: Bool,
        isAcceptingOrders: Bool,
        isLive: Bool,
        resolutionStatus: PolymarketResolutionStatus,
        settlement: PolymarketPositionSettlement?
    ) {
        self.conditionId = conditionId
        self.assetId = assetId
        self.marketId = marketId
        self.eventId = eventId
        self.eventTitle = eventTitle
        self.title = title
        self.iconURL = iconURL
        self.endDate = endDate
        self.outcome = outcome
        self.size = size
        self.avgPrice = avgPrice
        self.curPrice = curPrice
        self.initialValue = initialValue
        self.currentValue = currentValue
        self.cashPnl = cashPnl
        self.pnlRatio = pnlRatio
        self.realizedPnl = realizedPnl
        self.isRedeemable = isRedeemable
        self.isNegRisk = isNegRisk
        self.isAcceptingOrders = isAcceptingOrders
        self.isLive = isLive
        self.resolutionStatus = resolutionStatus
        self.settlement = settlement
    }
}

// MARK: - Statuses

public enum PolymarketResolutionStatus: String, Hashable, Sendable, CaseIterable {
    case open = "OPEN"
    case pendingResolution = "PENDING_RESOLUTION"
    case proposed = "PROPOSED"
    case disputed = "DISPUTED"
    case resolved = "RESOLVED"
    case unknown = "UNKNOWN"
}

public enum PolymarketPositionSettlement: String, Hashable, Sendable, CaseIterable {
    case won = "WON"
    case lost = "LOST"
    case split = "SPLIT"
    case unknown = "UNKNOWN"
}

// MARK: - Page

public struct PolymarketPositionsPage: Hashable, Sendable {
    public let positions: [PolymarketPosition]
    public let receivedCount: Int
    public let hasNext: Bool

    public init(positions: [PolymarketPosition], receivedCount: Int, hasNext: Bool) {
        self.positions = positions
        self.receivedCount = receivedCount
        self.hasNext = hasNext
    }
}
