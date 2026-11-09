//
//  PolymarketGeoblockStateProviderTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
import TangemPolymarket
@testable import Tangem

@Suite("Polymarket region state", .timeLimit(.minutes(1)))
struct PolymarketGeoblockStateProviderTests {
    @Test("An allowed region reads as allowed")
    func allowedRegion() async throws {
        let provider = CommonPolymarketGeoblockStateProvider(geoblockService: PolymarketGeoblockServiceStub(isBlocked: false))

        #expect(await Self.firstKnownState(of: provider) == .allowed)
    }

    @Test("A blocked region reads as blocked")
    func blockedRegion() async throws {
        let provider = CommonPolymarketGeoblockStateProvider(geoblockService: PolymarketGeoblockServiceStub(isBlocked: true))

        #expect(await Self.firstKnownState(of: provider) == .blocked)
    }

    @Test("A region that cannot be read leaves trading allowed rather than claiming a restriction")
    func unreadableRegionLeavesTradingAllowed() async throws {
        let service = PolymarketGeoblockServiceStub(error: PolymarketAPIError.connection(underlying: URLError(.timedOut)))
        let provider = CommonPolymarketGeoblockStateProvider(geoblockService: service)

        #expect(await Self.firstKnownState(of: provider) == .allowed)
    }

    @Test("A refresh reads the region again and lifts a restriction that no longer applies")
    func refreshReadsTheRegionAgain() async throws {
        let service = QueuedGeoblockServiceStub(isBlocked: [true, false])
        let provider = CommonPolymarketGeoblockStateProvider(geoblockService: service)
        #expect(await Self.firstKnownState(of: provider) == .blocked)

        provider.refresh()

        _ = await provider.statePublisher.firstValue { $0 == .allowed }
        #expect(service.calls == 2)
    }
}

// MARK: - Helpers

private extension PolymarketGeoblockStateProviderTests {
    static func firstKnownState(of provider: CommonPolymarketGeoblockStateProvider) async -> PolymarketGeoblockState? {
        await provider.statePublisher.firstValue { $0 != .unknown }
    }
}

// MARK: - Doubles

private final class QueuedGeoblockServiceStub: PolymarketGeoblockService, Sendable {
    private let state: OSAllocatedUnfairLock<State>

    var calls: Int {
        state.withLock { $0.calls }
    }

    init(isBlocked: [Bool]) {
        state = OSAllocatedUnfairLock(initialState: State(queued: isBlocked))
    }

    func geoblock() async throws -> PolymarketGeoblock {
        let isBlocked = state.withLock { state -> Bool in
            state.calls += 1
            return state.queued.removeFirst()
        }

        return PolymarketGeoblock(isBlocked: isBlocked, country: nil, region: nil)
    }

    private struct State {
        var queued: [Bool]
        var calls = 0
    }
}
