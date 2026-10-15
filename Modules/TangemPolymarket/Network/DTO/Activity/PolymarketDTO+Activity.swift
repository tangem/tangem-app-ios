//
//  PolymarketDTO+Activity.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension PolymarketDTO {
    struct ActivityResponse: Decodable {
        let items: [ActivityItem]
        let nextCursor: String?
    }

    struct ActivityItem: Decodable {
        let id: String
        let type: String
        let occurredAt: String?
        let amount: String?
        let transactionHash: String?
        let market: ActivityMarket?
        let order: ActivityOrder?
        let redeem: ActivityRedeem?
    }

    struct ActivityMarket: Decodable {
        let conditionId: String
        let outcomeIndex: Int?
        let shares: String?
        let outcome: String?
        let marketId: String?
        let slug: String?
        let title: String?
        let icon: String?
        let image: String?
        let endDate: String?
        let negRisk: Bool?
        let event: ActivityEvent?
    }

    struct ActivityEvent: Decodable {
        let eventId: String
        let slug: String?
        let title: String?
        let icon: String?
        let image: String?
        let endDate: String?
    }

    struct ActivityOrder: Decodable {
        let assetId: String?
        let averagePrice: String?
        let platformFee: String?
        let builderFee: String?
        let notional: String?
        let tradeCount: Int?
    }

    struct ActivityRedeem: Decodable {
        let result: String?
    }
}

// MARK: - Deposits reconcile

extension PolymarketDTO {
    struct DepositsReconcileResponse: Decodable {
        let state: String?
        let retryAfterSeconds: Int?
    }
}
