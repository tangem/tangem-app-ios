//
//  PolymarketPositionsServiceTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemPolymarket
@testable import Tangem

@Suite("Polymarket positions service")
struct PolymarketPositionsServiceTests {
    @Test("Active positions keep the backend order across pages")
    func activePositionsKeepBackendOrderAcrossPages() async throws {
        let api = PolymarketAPIProviderStub()
        api.positionPages = [
            nil: Self.page([Self.later, Self.sooner], nextCursor: "next"),
            "next": Self.page([Self.withoutEndDate, Self.soonest], nextCursor: nil),
        ]

        let page = try await Self.makeSUT(api: api).activePositions(limit: 4)

        #expect(page.positions.map(\.conditionId) == ["later", "sooner", "noEnd", "soonest"])
    }

    @Test("The limit keeps the first positions the backend sent")
    func limitKeepsTheFirstBackendPositions() async throws {
        let api = PolymarketAPIProviderStub()
        api.positionPages = [
            nil: Self.page([Self.later, Self.withoutEndDate, Self.soonest], nextCursor: "next"),
        ]

        let page = try await Self.makeSUT(api: api).activePositions(limit: 2)

        #expect(page.positions.map(\.conditionId) == ["later", "noEnd"])
    }

    @Test("A resolved position stays among the active ones before its payout lands on-chain", arguments: [
        PolymarketPositionSettlement.won,
        .lost,
        .split,
    ])
    func resolvedPositionWaitingForPayoutStays(settlement: PolymarketPositionSettlement) async throws {
        let sut = Self.makeSUT(positions: [
            .stub(conditionId: "open"),
            .stub(conditionId: "waiting", isRedeemable: false, settlement: settlement),
            .stub(conditionId: "claimable", isRedeemable: true, settlement: settlement),
        ])

        let page = try await sut.activePositions(limit: 10)

        #expect(Set(page.positions.map(\.conditionId)) == ["open", "waiting", "claimable"])
    }

    @Test("A position the user has sold out of stays hidden, resolved or not", arguments: [
        PolymarketPositionSettlement?.none,
        .won,
    ])
    func emptiedPositionIsHidden(settlement: PolymarketPositionSettlement?) async throws {
        let sut = Self.makeSUT(positions: [
            .stub(conditionId: "held"),
            .stub(conditionId: "sold", size: 0, isRedeemable: settlement != nil, settlement: settlement),
        ])

        let page = try await sut.activePositions(limit: 10)

        #expect(page.positions.map(\.conditionId) == ["held"])
    }
}

// MARK: - Helpers

private extension PolymarketPositionsServiceTests {
    static let now = Date(timeIntervalSince1970: 1_800_000_000)
    static let later = PolymarketPosition.stub(conditionId: "later", endDate: now.addingTimeInterval(3 * 86400))
    static let sooner = PolymarketPosition.stub(conditionId: "sooner", endDate: now.addingTimeInterval(86400))
    static let soonest = PolymarketPosition.stub(conditionId: "soonest", endDate: now)
    static let withoutEndDate = PolymarketPosition.stub(conditionId: "noEnd")

    static func page(_ positions: [PolymarketPosition], nextCursor: String?) -> PolymarketPositionsPage {
        PolymarketPositionsPage(positions: positions, receivedCount: positions.count, nextCursor: nextCursor)
    }

    static func makeSUT(positions: [PolymarketPosition]) -> CommonPolymarketPositionsService {
        let api = PolymarketAPIProviderStub()
        api.positionPages = [nil: page(positions, nextCursor: nil)]

        return makeSUT(api: api)
    }

    static func makeSUT(api: PolymarketAPIProviderStub) -> CommonPolymarketPositionsService {
        CommonPolymarketPositionsService(
            ownerAddressProvider: PolymarketOwnerAddressProviderStub(derived: PolymarketOwnerAddressProviderStub.ownerAddress),
            apiProvider: api
        )
    }
}
