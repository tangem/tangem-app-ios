//
//  PolymarketPositionTypeFilterTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemPolymarket
@testable import Tangem

@Suite("Polymarket position type filter")
struct PolymarketPositionTypeFilterTests {
    @Test("All keeps every row of both lists")
    func allKeepsEverything() {
        #expect(PolymarketPositionTypeFilter.all.accepts(Self.open(resolution: .disputed, settlement: nil)))
        #expect(PolymarketPositionTypeFilter.all.accepts(Self.closed(status: .lost)))
    }

    @Test("The live states read the resolution, not the settlement", arguments: [
        (PolymarketPositionTypeFilter.active, PolymarketResolutionStatus.open),
        (.disputed, .disputed),
        (.pending, .pendingResolution),
    ])
    func liveStatesFollowResolution(filter: PolymarketPositionTypeFilter, resolution: PolymarketResolutionStatus) {
        #expect(filter.accepts(Self.open(resolution: resolution, settlement: nil)))
        #expect(filter.accepts(Self.open(resolution: resolution, settlement: .won)))
        #expect(!filter.accepts(Self.open(resolution: .resolved, settlement: .won)))

        for sibling in PolymarketResolutionStatus.allCases where sibling != resolution {
            guard !(filter == .pending && sibling == .proposed) else { continue }

            #expect(!filter.accepts(Self.open(resolution: sibling, settlement: nil)))
        }
    }

    @Test("A proposed result is awaiting one too")
    func proposedCountsAsPending() {
        #expect(PolymarketPositionTypeFilter.pending.accepts(Self.open(resolution: .proposed, settlement: nil)))
    }

    @Test("The settled states read the settlement", arguments: [
        (PolymarketPositionTypeFilter.won, PolymarketPositionSettlement.won),
        (.lost, .lost),
        (.split, .split),
    ])
    func settledStatesFollowSettlement(filter: PolymarketPositionTypeFilter, settlement: PolymarketPositionSettlement) {
        #expect(filter.accepts(Self.open(resolution: .resolved, settlement: settlement)))
        #expect(!filter.accepts(Self.open(resolution: .open, settlement: nil)))

        for sibling in PolymarketPositionSettlement.allCases where sibling != settlement {
            #expect(!filter.accepts(Self.open(resolution: .resolved, settlement: sibling)))
        }
    }

    @Test("A closed row matches its own ending", arguments: [
        (PolymarketPositionTypeFilter.won, PolymarketClosedPositionStatus.won),
        (.lost, .lost),
        (.split, .split),
        (.closed, .closed),
        (.unknown, .unknown),
    ])
    func closedRowsFollowStatus(filter: PolymarketPositionTypeFilter, status: PolymarketClosedPositionStatus) {
        #expect(filter.accepts(Self.closed(status: status)))

        for sibling in PolymarketClosedPositionStatus.allCases where sibling != status {
            #expect(!filter.accepts(Self.closed(status: sibling)))
        }
    }

    @Test("An unrecognised ending is its own state, not every state")
    func unknownStaysUnknown() {
        #expect(PolymarketPositionTypeFilter.unknown.accepts(Self.open(resolution: .unknown, settlement: .unknown)))
        #expect(!PolymarketPositionTypeFilter.unknown.accepts(Self.open(resolution: .resolved, settlement: .won)))
    }

    @Test("Nothing closed is live, so the live states match no closed row", arguments: [
        PolymarketPositionTypeFilter.active,
        .disputed,
        .pending,
    ])
    func liveStatesMatchNoClosedRow(filter: PolymarketPositionTypeFilter) {
        for status in PolymarketClosedPositionStatus.allCases {
            #expect(!filter.accepts(Self.closed(status: status)))
        }
    }
}

// MARK: - Fixtures

private extension PolymarketPositionTypeFilterTests {
    static func open(
        resolution: PolymarketResolutionStatus,
        settlement: PolymarketPositionSettlement?
    ) -> PolymarketPosition {
        PolymarketPosition(
            conditionId: "0x1",
            assetId: "2",
            marketId: "3",
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
            isRedeemable: false,
            isNegRisk: false,
            isAcceptingOrders: true,
            isLive: false,
            resolutionStatus: resolution,
            settlement: settlement
        )
    }

    static func closed(status: PolymarketClosedPositionStatus) -> PolymarketClosedPosition {
        PolymarketClosedPosition(
            conditionId: "0x1",
            assetId: "2",
            title: "Question",
            slug: nil,
            iconURL: nil,
            closedAt: nil,
            outcome: "Yes",
            outcomeIndex: 0,
            avgPrice: 1,
            curPrice: 1,
            totalBought: 1,
            realizedPnl: 0,
            status: status
        )
    }
}
