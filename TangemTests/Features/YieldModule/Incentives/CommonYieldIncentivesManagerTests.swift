//
//  CommonYieldIncentivesManagerTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import Testing
@testable import Tangem

@Suite("CommonYieldIncentivesManager", .serialized, .timeLimit(.minutes(1)))
struct CommonYieldIncentivesManagerTests {
    private typealias Fixtures = YieldIncentivesFixtures

    @Test("A second read inside the cache window is served without a request")
    func cachedReadSkipsTheNetwork() async throws {
        let network = YieldClaimNetworkManagerStub()

        try await withInjectedYieldNetworkManager(network) {
            let sut = makeSUT()

            _ = try await sut.incentives()
            let cached = try await sut.incentives()

            #expect(network.incentivesCallCount == 1)
            #expect(cached == Fixtures.summary())
        }
    }

    @Test("A forced read goes to the network even with a warm cache")
    func forcedReadSkipsTheCache() async throws {
        let network = YieldClaimNetworkManagerStub()

        try await withInjectedYieldNetworkManager(network) {
            let sut = makeSUT()

            _ = try await sut.incentives()
            _ = try await sut.incentives(forceRefresh: true)

            #expect(network.incentivesCallCount == 2)
        }
    }

    @Test("Two cold reads make a single request")
    func concurrentColdReadsShareOneRequest() async throws {
        let shared = Fixtures.summary(rewards: [Fixtures.reward(symbol: "SHARED")])
        let separate = Fixtures.summary(rewards: [Fixtures.reward(symbol: "SEPARATE")])

        let network = YieldClaimNetworkManagerStub()
        network.setIncentivesResults([.success(shared), .success(separate)])

        let gate = YieldAsyncGate()
        network.gateCall(at: 0, with: gate)

        try await withInjectedYieldNetworkManager(network) {
            let sut = makeSUT()
            let arrivals = Arrivals()

            @Sendable
            func read() async throws -> YieldIncentivesRewardsSummary? {
                await arrivals.arrive()
                return try await sut.incentives()
            }

            async let first = read()
            await gate.waitForArrival()
            async let second = read()

            while await arrivals.count < 2 {
                await Task.yield()
            }

            #expect(network.incentivesCallCount == 1)

            gate.open()

            let results = try await (first, second)

            #expect(results.0 == shared)
            #expect(results.1 == shared)
            #expect(network.incentivesCallCount == 1)
        }
    }

    @Test("An absent module is cached like any other answer")
    func absentModuleIsCached() async throws {
        let network = YieldClaimNetworkManagerStub()
        network.setIncentivesResults([.success(nil)])

        try await withInjectedYieldNetworkManager(network) {
            let sut = makeSUT()

            let first = try await sut.incentives()
            let second = try await sut.incentives()

            #expect(first == nil)
            #expect(second == nil)
            #expect(network.incentivesCallCount == 1)
        }
    }

    @Test("A failed read is reported instead of being answered from the cache")
    func failedReadIsReported() async throws {
        let network = YieldClaimNetworkManagerStub()
        network.setIncentivesResults([.success(Fixtures.summary()), .failure(YieldIncentivesTestError.network)])

        try await withInjectedYieldNetworkManager(network) {
            let sut = makeSUT()

            _ = try await sut.incentives()

            await #expect(throws: YieldIncentivesTestError.network) {
                _ = try await sut.incentives(forceRefresh: true)
            }
        }
    }

    @Test("A response that arrives late never replaces a newer one")
    func lateResponseNeverReplacesANewerOne() async throws {
        let late = Fixtures.summary(rewards: [Fixtures.reward(symbol: "LATE")])
        let fresh = Fixtures.summary(rewards: [Fixtures.reward(symbol: "FRESH")])

        let network = YieldClaimNetworkManagerStub()
        network.setIncentivesResults([.success(late), .success(fresh)])

        let gate = YieldAsyncGate()
        network.gateCall(at: 0, with: gate)

        try await withInjectedYieldNetworkManager(network) {
            let sut = makeSUT()

            async let delayed = sut.incentives(forceRefresh: true)
            await gate.waitForArrival()

            _ = try await sut.incentives(forceRefresh: true)
            gate.open()

            let delayedResult = try await delayed
            let cached = try await sut.incentives()

            #expect(delayedResult == fresh)
            #expect(cached == fresh)
        }
    }

    @Test("Incentives managers are shared per chain and owner, and never across them")
    func incentivesManagersAreSharedPerChainAndOwner() {
        let provider = YieldIncentivesManagerProvider()

        let manager = provider.manager(chainId: 143, userAddress: "0xABC")
        let sameOwner = provider.manager(chainId: 143, userAddress: "0xabc")
        let otherChain = provider.manager(chainId: 1, userAddress: "0xABC")
        let otherOwner = provider.manager(chainId: 143, userAddress: "0xDEF")

        #expect(manager === sameOwner)
        #expect(manager !== otherChain)
        #expect(manager !== otherOwner)
    }

    private func makeSUT() -> CommonYieldIncentivesManager {
        CommonYieldIncentivesManager(chainId: Fixtures.chainId, userAddress: Fixtures.userAddress)
    }
}

private actor Arrivals {
    private(set) var count = 0

    func arrive() {
        count += 1
    }
}
