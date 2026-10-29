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

    static func makeSUT(api: PolymarketAPIProviderStub) -> CommonPolymarketPositionsService {
        CommonPolymarketPositionsService(
            ownerAddressProvider: PolymarketOwnerAddressProviderStub(derived: PolymarketOwnerAddressProviderStub.ownerAddress),
            apiProvider: api
        )
    }
}
