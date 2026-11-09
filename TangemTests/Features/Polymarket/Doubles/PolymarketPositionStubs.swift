//
//  PolymarketPositionStubs.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket

extension PolymarketPosition {
    static func stub(
        conditionId: String = "0xcondition",
        endDate: Date? = nil,
        size: Decimal = 10,
        cashPnl: Decimal = 0,
        realizedPnl: Decimal = 0,
        isRedeemable: Bool = false,
        settlement: PolymarketPositionSettlement? = nil,
        resolutionStatus: PolymarketResolutionStatus? = nil,
        isAcceptingOrders: Bool? = nil
    ) -> PolymarketPosition {
        PolymarketPosition(
            conditionId: conditionId,
            assetId: "1",
            marketId: "market",
            version: .v1,
            eventId: "event",
            eventTitle: "Event",
            title: "Question",
            iconURL: nil,
            endDate: endDate,
            outcome: "Yes",
            outcomeIndex: 0,
            size: size,
            avgPrice: Decimal(string: "0.5")!,
            curPrice: Decimal(string: "0.5")!,
            initialValue: 5,
            currentValue: 5,
            cashPnl: cashPnl,
            pnlRatio: 0,
            realizedPnl: realizedPnl,
            isRedeemable: isRedeemable,
            isNegRisk: false,
            isAcceptingOrders: isAcceptingOrders ?? (settlement == nil),
            isLive: false,
            resolutionStatus: resolutionStatus ?? (settlement == nil ? .open : .resolved),
            settlement: settlement
        )
    }
}

extension PolymarketClosedPosition {
    static func stub(status: PolymarketClosedPositionStatus, realizedPnl: Decimal) -> PolymarketClosedPosition {
        PolymarketClosedPosition(
            conditionId: "0xclosed",
            assetId: "1",
            title: "Question",
            slug: nil,
            iconURL: nil,
            closedAt: nil,
            outcome: "Yes",
            outcomeIndex: 0,
            avgPrice: Decimal(string: "0.5")!,
            curPrice: 1,
            totalBought: 10,
            realizedPnl: realizedPnl,
            status: status
        )
    }
}
