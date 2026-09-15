//
//  PolymarketDTO+Positions.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension PolymarketDTO {
    struct PositionsResponse: Decodable {
        let positions: [Position]
        let hasNext: Bool?
    }

    struct ClosedPositionsResponse: Decodable {
        let positions: [ClosedPosition]
        let hasNext: Bool?
    }

    struct ClosedPosition: Decodable {
        let conditionId: String
        let assetId: String
        let title: String?
        let slug: String?
        let icon: String?
        let closedAt: String?
        let outcome: String?
        let avgPrice: String?
        let curPrice: String?
        let totalBought: String?
        let realizedPnl: String?
        let status: String?
    }

    struct Position: Decodable {
        let conditionId: String
        let assetId: String
        let marketId: String?
        let eventId: String?
        let eventTitle: String?
        let title: String?
        let slug: String?
        let icon: String?
        let endDate: String?
        let outcome: String?
        let size: String?
        let avgPrice: String?
        let curPrice: String?
        let initialValue: String?
        let currentValue: String?
        let cashPnl: String?
        let percentPnl: String?
        let realizedPnl: String?
        let totalBought: String?
        let redeemable: Bool?
        let negRisk: Bool?
        let acceptingOrders: Bool?
        let live: Bool?
        let resolutionStatus: String?
        let status: String?
    }
}

// MARK: - One open position

extension PolymarketDTO {
    struct PositionOutcomeResponse: Decodable {
        let position: Position?
    }
}
