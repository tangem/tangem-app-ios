//
//  LendingRateRepositoryTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import Testing
import TangemFoundation
@testable import Tangem

@Suite("Lending on Aave rate repository", .timeLimit(.minutes(1)))
struct LendingRateRepositoryTests {
    @Test("Every ETH row shares one rate request")
    func oneRequestForAllRows() async throws {
        let provider = LendingRateProviderSpy(rates: [Decimal(24) / 1000])
        let sut = makeSUT(provider: provider)
        let (stream, subscription) = publishedRates(of: sut)
        var rates = stream.makeAsyncIterator()

        sut.loadApyIfNeeded()
        sut.loadApyIfNeeded()
        let rate = await rates.next()
        subscription.cancel()

        #expect(rate == Decimal(24) / 1000)
        #expect(provider.calls == 1)
    }

    @Test(
        "A row asks for the rate only when nothing has it yet and no request is running",
        arguments: [
            (false, false, true),
            (true, false, false),
            (false, true, false),
            (true, true, false),
        ]
    )
    func shouldLoad(isLoading: Bool, hasApy: Bool, expected: Bool) {
        #expect(CommonLendingRateRepository.shouldLoad(isLoading: isLoading, hasApy: hasApy) == expected)
    }

    @Test("A fresh rate read on the token page reaches the rows already showing the old one")
    func refreshReachesSubscribers() async throws {
        let provider = LendingRateProviderSpy(rates: [Decimal(24) / 1000, Decimal(35) / 1000])
        let sut = makeSUT(provider: provider)
        let (stream, subscription) = publishedRates(of: sut)
        var rates = stream.makeAsyncIterator()

        sut.loadApyIfNeeded()
        let initial = await rates.next()
        let refreshed = try await sut.refreshApy()
        let delivered = await rates.next()
        subscription.cancel()

        #expect(initial == Decimal(24) / 1000)
        #expect(refreshed == Decimal(35) / 1000)
        #expect(delivered == Decimal(35) / 1000)
    }

    @Test("A slow earlier rate read doesn't replace the newer rate")
    func staleRateIsDropped() async throws {
        let provider = GatedLendingRateProviderStub(results: [.success(Decimal(24) / 1000), .success(Decimal(35) / 1000)])
        let sut = makeSUT(provider: provider)

        let slow = Task { try await sut.refreshApy() }
        await provider.started(call: 0)
        let fast = Task { try await sut.refreshApy() }
        await provider.started(call: 1)

        provider.finish(call: 1)
        _ = try await fast.value
        provider.finish(call: 0)
        _ = try await slow.value

        #expect(sut.apy == Decimal(35) / 1000)
    }

    @Test("An earlier rate read still reaches the rows when the newer one fails")
    func earlierRateSurvivesFailedNewerRead() async throws {
        let provider = GatedLendingRateProviderStub(results: [.success(Decimal(24) / 1000), .failure(RateErrorStub())])
        let sut = makeSUT(provider: provider)

        let earlier = Task { try await sut.refreshApy() }
        await provider.started(call: 0)
        let newer = Task { try await sut.refreshApy() }
        await provider.started(call: 1)

        provider.finish(call: 1)
        _ = try? await newer.value
        provider.finish(call: 0)
        _ = try await earlier.value

        #expect(sut.apy == Decimal(24) / 1000)
    }
}

// MARK: - Helpers

private extension LendingRateRepositoryTests {
    func makeSUT(provider: LendingRateProvider) -> CommonLendingRateRepository {
        CommonLendingRateRepository(provider: provider)
    }

    func publishedRates(of sut: CommonLendingRateRepository) -> (AsyncStream<Decimal>, AnyCancellable) {
        let (rates, continuation) = AsyncStream.makeStream(of: Decimal.self)
        let subscription = sut.apyPublisher
            .compactMap { $0 }
            .sink { continuation.yield($0) }

        return (rates, subscription)
    }
}

// MARK: - Stubs

private struct RateErrorStub: Error {}

private final class LendingRateProviderSpy: LendingRateProvider {
    private let state: OSAllocatedUnfairLock<(rates: [Decimal], calls: Int)>

    init(rates: [Decimal]) {
        state = OSAllocatedUnfairLock(initialState: (rates, 0))
    }

    var calls: Int {
        state.withLock { $0.calls }
    }

    func currentApy() async throws -> Decimal {
        state.withLock { state in
            let rate = state.rates[min(state.calls, state.rates.count - 1)]
            state.calls += 1
            return rate
        }
    }
}

private final class GatedLendingRateProviderStub: LendingRateProvider {
    private let results: [Result<Decimal, Error>]
    private let startGates: [TestGate]
    private let finishGates: [TestGate]
    private let callCount = OSAllocatedUnfairLock(initialState: 0)

    init(results: [Result<Decimal, Error>]) {
        self.results = results
        startGates = results.map { _ in TestGate() }
        finishGates = results.map { _ in TestGate() }
    }

    func currentApy() async throws -> Decimal {
        let call = callCount.withLock { count in
            defer { count += 1 }
            return count
        }

        startGates[call].open()
        await finishGates[call].wait()
        return try results[call].get()
    }

    func started(call: Int) async {
        await startGates[call].wait()
    }

    func finish(call: Int) {
        finishGates[call].open()
    }
}
