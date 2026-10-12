//
//  CollectiblesMachineViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemTestKit
@testable import Tangem

@Suite("CollectiblesMachineViewModel", .serialized, .timeLimit(.minutes(1)))
@MainActor
final class CollectiblesMachineViewModelTests: LeakTrackingTestSuite {
    typealias SUT = CollectiblesMachineViewModel

    @Test("Renders the header straight from the tapped pack, ahead of any response")
    func rendersHeaderFromPack() {
        let sut = makeSUT()

        #expect(sut.title == "Elite pack")
        #expect(sut.artworkURL == URL(string: "https://example.com/pack.png"))
        #expect(sut.openButtonText == "Open for \(Self.priceText(50))")
        #expect(sut.state.isContent == false)
    }

    @Test("First fetch lands as content")
    func loadsContent() async {
        let provider = MachineProviderStub(results: [.success(Self.machine())])
        let sut = makeSUT(provider: provider)

        sut.load()
        await waitUntil { sut.state.isContent }
        await stopPolling(sut)

        guard case .content(let details) = sut.state else {
            Issue.record("Expected the content state")
            return
        }

        #expect(details.tiers.map(\.tier) == [.common, .rare, .epic])
        #expect(details.cardsCountText == "1 card")
    }

    @Test("A poll response refreshes the header and the CTA price")
    func refreshesHeaderFromPolling() async {
        let provider = MachineProviderStub(results: [.success(Self.machine(name: "Repriced pack", price: 55))])
        let sut = makeSUT(provider: provider)

        sut.load()
        await waitUntil { sut.state.isContent }
        await stopPolling(sut)

        #expect(sut.title == "Repriced pack")
        #expect(sut.openButtonText == "Open for \(Self.priceText(55))")
    }

    @Test("Retry refetches right away instead of waiting for the next tick")
    func failsAndRetries() async {
        let provider = MachineProviderStub(results: [
            .failure(URLError(.notConnectedToInternet)),
            .success(Self.machine()),
        ])
        let sut = makeSUT(provider: provider)

        sut.load()
        await waitUntil { sut.state.isFailed }

        sut.retry()
        await waitUntil { sut.state.isContent }
        await stopPolling(sut)

        #expect(provider.loadCallsCount == 2)
    }

    @Test("A repeated load call does not start a second polling loop")
    func loadIsIdempotent() async {
        let provider = MachineProviderStub(results: [.success(Self.machine())])
        let sut = makeSUT(provider: provider)

        sut.load()
        await waitUntil { sut.state.isContent }

        let runningLoop = sut.pollingTask
        sut.load()

        // Identity rather than the call count: a second loop would be cancelled before it ever reached the provider
        #expect(sut.pollingTask == runningLoop)

        await stopPolling(sut)

        #expect(provider.loadCallsCount == 1)
    }

    @Test("A silent refresh that fails leaves the last values on screen while the loop keeps polling")
    func failedRefreshKeepsTheLastValues() async {
        // Every call past the first one fails, so a screen reset cannot be masked by a later success.
        let provider = MachineProviderStub(results: [
            .success(Self.machine()),
            .failure(URLError(.timedOut)),
        ])
        let sut = makeSUT(provider: provider, pollInterval: .milliseconds(10))

        sut.load()
        // The loop is sequential, so a third call proves the second one's failure was handled to the end.
        await waitUntil { provider.loadCallsCount >= 3 }
        await stopPolling(sut)

        #expect(sut.state.isContent)
    }
}

// MARK: - Helpers

private extension CollectiblesMachineViewModelTests {
    func makeSUT(
        provider: (any CollectiblesMachineProvider)? = nil,
        pollInterval: Duration = .seconds(60)
    ) -> SUT {
        let sut = SUT(
            pack: Self.pack(),
            provider: provider ?? MachineProviderStub(results: [.success(Self.machine())]),
            pollInterval: pollInterval
        )
        return trackForMemoryLeaks(sut)
    }

    static func pack() -> CollectiblesPack {
        CollectiblesPack(
            id: "pokemon_50",
            name: "Elite pack",
            loreID: "pokemon",
            price: 50,
            currencyCode: "USD",
            buybackRate: Decimal(string: "0.85")!,
            artworkURL: URL(string: "https://example.com/pack.png")
        )
    }

    func waitUntil(
        timeout: Duration = .seconds(5),
        _ condition: @escaping @MainActor () -> Bool
    ) async {
        let deadline = ContinuousClock.now + timeout
        while !condition() {
            if ContinuousClock.now >= deadline {
                Issue.record("waitUntil timed out")
                return
            }
            // Respects the suite's time limit: swallowing the cancellation would spin the loop to its own deadline.
            do {
                try await Task.sleep(for: .milliseconds(10))
            } catch {
                return
            }
        }
    }

    /// Waits for the loop to unwind so the leak check does not race the in-flight request.
    func stopPolling(_ sut: SUT) async {
        let task = sut.pollingTask
        sut.stopPolling()
        await task?.value
    }

    /// Spells the expected money format out instead of reusing the app preset, so a change to the preset fails here.
    static func priceText(_ price: Decimal) -> String {
        let options = BalanceFormattingOptions(
            minFractionDigits: 0,
            maxFractionDigits: 2,
            formatEpsilonAsLowestRepresentableValue: true,
            roundingType: .default(roundingMode: .plain, scale: 2)
        )
        let formatter = BalanceFormatter().makeDecimalFormatter(formattingOptions: options)
        formatter.locale = Locale(identifier: "en_US")
        let amount = BalanceFormatter().formatDecimal(price, formattingOptions: options, formatter: formatter)

        return "\(amount) USDC"
    }

    static func machine(name: String = "Elite pack", price: Decimal = 50) -> CollectiblesMachine {
        CollectiblesMachine(
            name: name,
            artworkURL: nil,
            price: price,
            cardsPerPack: 1,
            buybackRate: Decimal(string: "0.85")!,
            expectedValue: Decimal(string: "53.95")!,
            tiers: [
                .init(tier: .common, odds: Decimal(string: "0.8")!, valueRange: 15 ... 40),
                .init(tier: .rare, odds: Decimal(string: "0.04")!, valueRange: 110 ... 250),
                .init(tier: .epic, odds: Decimal(string: "0.01")!, valueRange: 250 ... 5001),
            ]
        )
    }
}

// MARK: - Stubs

@MainActor
private final class MachineProviderStub: CollectiblesMachineProvider {
    private(set) var loadCallsCount = 0

    private var results: [Result<CollectiblesMachine, any Error>]

    /// The last result repeats once the script runs out, so an extra poll tick never crashes the test.
    init(results: [Result<CollectiblesMachine, any Error>]) {
        self.results = results
    }

    func load(id: String) async throws -> CollectiblesMachine {
        loadCallsCount += 1

        let result = results.count > 1 ? results.removeFirst() : results[0]
        return try result.get()
    }
}
