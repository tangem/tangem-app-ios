//
//  PolymarketPositionClaimTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemPolymarket
@testable import Tangem

@Suite("Polymarket position claim availability", .timeLimit(.minutes(1)))
struct PolymarketPositionClaimTests {
    @Test("A tapped position opens the claim only when it is settled or redeemable on a market version this build can redeem", arguments: [
        ClaimCase(settlement: nil, isRedeemable: false, version: .v1, opensClaim: false),
        ClaimCase(settlement: nil, isRedeemable: true, version: .v1, opensClaim: true),
        ClaimCase(settlement: .won, isRedeemable: false, version: .v1, opensClaim: true),
        ClaimCase(settlement: .lost, isRedeemable: false, version: .v1, opensClaim: true),
        ClaimCase(settlement: .split, isRedeemable: false, version: .v2, opensClaim: true),
        ClaimCase(settlement: .unknown, isRedeemable: false, version: .v1, opensClaim: false),
        ClaimCase(settlement: .unknown, isRedeemable: true, version: .v2, opensClaim: true),
        ClaimCase(settlement: .won, isRedeemable: true, version: .unknown("v3"), opensClaim: false),
        ClaimCase(settlement: nil, isRedeemable: true, version: .unknown("v3"), opensClaim: false),
        ClaimCase(settlement: .won, isRedeemable: true, version: nil, opensClaim: false),
    ])
    func opensClaim(_ claimCase: ClaimCase) {
        #expect(claimCase.position.opensClaim == claimCase.opensClaim)
    }
}

// MARK: - Cases

extension PolymarketPositionClaimTests {
    struct ClaimCase: Sendable, CustomTestStringConvertible {
        let settlement: PolymarketPositionSettlement?
        let isRedeemable: Bool
        let version: PolymarketMarketVersion?
        let opensClaim: Bool

        var testDescription: String {
            "settlement \(settlement.map(\.rawValue) ?? "none"), redeemable \(isRedeemable), version \(version.map { "\($0)" } ?? "none")"
        }

        var position: PolymarketPosition {
            PolymarketPosition(
                conditionId: "0x1",
                assetId: "2",
                marketId: "3",
                version: version,
                eventId: "4",
                eventTitle: "Event",
                title: "Question",
                iconURL: nil,
                endDate: nil,
                outcome: "Yes",
                outcomeIndex: 0,
                size: 1,
                avgPrice: 1,
                curPrice: 1,
                initialValue: 1,
                currentValue: 1,
                cashPnl: 0,
                pnlRatio: 0,
                realizedPnl: 0,
                isRedeemable: isRedeemable,
                isNegRisk: false,
                isAcceptingOrders: true,
                isLive: false,
                resolutionStatus: settlement == nil ? .open : .resolved,
                settlement: settlement
            )
        }
    }
}
