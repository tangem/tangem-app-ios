//
//  PolymarketGeoblockStateProviderTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemPolymarket
@testable import Tangem

@Suite("Polymarket region state")
struct PolymarketGeoblockStateProviderTests {
    @Test("An allowed region reads as allowed")
    func allowedRegion() async throws {
        let provider = CommonPolymarketGeoblockStateProvider(geoblockService: PolymarketGeoblockServiceStub(isBlocked: false))

        try await settle { provider.state != .unknown }

        #expect(provider.state == .allowed)
    }

    @Test("A blocked region reads as blocked")
    func blockedRegion() async throws {
        let provider = CommonPolymarketGeoblockStateProvider(geoblockService: PolymarketGeoblockServiceStub(isBlocked: true))

        try await settle { provider.state != .unknown }

        #expect(provider.state == .blocked)
    }

    @Test("A region that cannot be read leaves trading allowed rather than claiming a restriction")
    func unreadableRegionLeavesTradingAllowed() async throws {
        let service = PolymarketGeoblockServiceStub(error: PolymarketAPIError.connection(underlying: URLError(.timedOut)))
        let provider = CommonPolymarketGeoblockStateProvider(geoblockService: service)

        try await settle { provider.state != .unknown }

        #expect(provider.state == .allowed)
    }
}

// MARK: - Helpers

private extension PolymarketGeoblockStateProviderTests {
    func settle(until isSatisfied: () -> Bool) async throws {
        for _ in 0 ..< 200 {
            if isSatisfied() { return }

            try await Task.sleep(nanoseconds: 10_000_000)
        }

        Issue.record("The region state never settled")
    }
}
