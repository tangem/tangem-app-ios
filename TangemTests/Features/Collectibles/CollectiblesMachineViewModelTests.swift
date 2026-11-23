//
//  CollectiblesMachineViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Testing
import UIKit
import TangemFoundation
import TangemTestKit
@testable import Tangem

@Suite("CollectiblesMachineViewModel", .serialized, .timeLimit(.minutes(1)))
@MainActor
final class CollectiblesMachineViewModelTests: LeakTrackingTestSuite {
    typealias SUT = CollectiblesMachineViewModel

    @Test("Renders the whole screen straight from the tapped pack, ahead of any response")
    func rendersFromPack() {
        let sut = makeSUT()

        #expect(sut.title == "Elite pack")
        #expect(sut.artworkURL == URL(string: "https://example.com/pack.png"))
        #expect(sut.openButtonText == "Open for \(Self.priceText(50))")

        #expect(sut.details.tiers.map(\.tier) == [.common, .rare, .epic])
        #expect(sut.details.cardsCountText == "1 card")
    }

    @Test("Opening does not request the machine the catalogue already delivered")
    func opensWithoutRequest() async throws {
        let provider = MachineProviderStub(results: [.success(Self.machine())])
        let sut = makeSUT(provider: provider)

        sut.onWillAppear()
        try await stopPolling(sut)

        #expect(provider.loadCallsCount == 0)
    }

    @Test("A poll response refreshes the header and the CTA price")
    func refreshesHeaderFromPolling() async throws {
        let provider = MachineProviderStub(results: [.success(Self.machine(name: "Repriced pack", price: 55))])
        let sut = makeSUT(provider: provider, pollInterval: .milliseconds(10))

        sut.onWillAppear()
        await sut.$title.firstValue { $0 == "Repriced pack" }
        try await stopPolling(sut)

        #expect(sut.title == "Repriced pack")
        #expect(sut.openButtonText == "Open for \(Self.priceText(55))")
    }

    @Test("A repeated load call does not start a second polling loop")
    func loadIsIdempotent() async throws {
        let provider = MachineProviderStub(results: [.success(Self.machine())])
        let sut = makeSUT(provider: provider)

        sut.onWillAppear()

        let runningLoop = sut.pollingTask
        sut.onWillAppear()

        // Identity rather than the call count: a second loop would be cancelled before it ever reached the provider
        #expect(sut.pollingTask == runningLoop)

        try await stopPolling(sut)
    }

    @Test("A silent refresh that fails leaves the last values on screen while the loop keeps polling")
    func failedRefreshKeepsTheLastValues() async throws {
        // Every call past the first one fails, so a screen reset cannot be masked by a later success.
        let provider = MachineProviderStub(results: [
            .success(Self.machine()),
            .failure(URLError(.timedOut)),
        ])
        let sut = makeSUT(provider: provider, pollInterval: .milliseconds(10))

        sut.onWillAppear()
        // The loop is sequential, so a third call proves the second one's failure was handled to the end.
        try await provider.loads.waitForCount(3)
        try await stopPolling(sut)

        #expect(sut.details.tiers.map(\.tier) == [.common, .rare, .epic])
    }

    @Test("Going to the background stops the polling loop")
    func backgroundStopsPolling() async throws {
        let notificationCenter = NotificationCenterSpy()
        let sut = makeSUT(notificationCenter: notificationCenter)

        sut.onWillAppear()
        try await notificationCenter.observation(of: .didEnterBackground)

        let pollingTask = sut.pollingTask
        notificationCenter.post(.didEnterBackground)
        try await pollingTask?.waitForCompletion()

        #expect(sut.pollingTask == nil)
    }

    @Test("Returning to the foreground fetches at once and resumes polling")
    func foregroundFetchesAndResumes() async throws {
        let notificationCenter = NotificationCenterSpy()
        let provider = MachineProviderStub(results: [.success(Self.machine(name: "Fresh pack"))])
        let sut = makeSUT(provider: provider, notificationCenter: notificationCenter)

        sut.onWillAppear()
        try await notificationCenter.observation(of: .didEnterBackground)
        try await notificationCenter.observation(of: .willEnterForeground)

        let pollingTask = sut.pollingTask
        notificationCenter.post(.didEnterBackground)
        try await pollingTask?.waitForCompletion()

        notificationCenter.post(.willEnterForeground)
        await sut.$title.firstValue { $0 == "Fresh pack" }

        #expect(provider.loadCallsCount == 1)
        #expect(sut.pollingTask != nil)

        try await stopPolling(sut)
    }

    @Test("Returning to the foreground off the screen leaves polling stopped")
    func foregroundOffScreenKeepsPollingStopped() async throws {
        let notificationCenter = NotificationCenterSpy()
        let provider = MachineProviderStub(results: [.success(Self.machine())])
        let sut = makeSUT(provider: provider, notificationCenter: notificationCenter)

        sut.onWillAppear()
        try await stopPolling(sut)
        try await notificationCenter.observation(of: .willEnterForeground)

        try await notificationCenter.postAndWaitForDelivery(.willEnterForeground)

        #expect(sut.pollingTask == nil)
        #expect(provider.loadCallsCount == 0)
    }

    @Test("A pack can't be opened while its purchase is locked", arguments: [true, false])
    func lockedPurchaseLocksOpening(isPurchaseLocked: Bool) {
        let sut = makeSUT(isPurchaseLocked: { isPurchaseLocked })

        #expect(sut.isOpenLocked == isPurchaseLocked)
    }

    @Test("The open button follows the purchase lock once the relink status changes")
    func relinkStatusChangeUpdatesOpening() async {
        var isPurchaseLocked = false
        let relinkStatusProvider = RelinkStatusProviderStub()
        let sut = makeSUT(relinkStatusProvider: relinkStatusProvider, isPurchaseLocked: { isPurchaseLocked })

        isPurchaseLocked = true
        relinkStatusProvider.isRelinkRequiredSubject.send(true)
        await sut.$isOpenLocked.firstValue { $0 }

        #expect(sut.isOpenLocked)
    }

    @Test("Appearing again picks up a purchase lock that changed while the screen was covered")
    func appearingUpdatesOpening() async throws {
        var isPurchaseLocked = false
        let sut = makeSUT(isPurchaseLocked: { isPurchaseLocked })

        isPurchaseLocked = true
        sut.onWillAppear()

        #expect(sut.isOpenLocked)
        try await stopPolling(sut)
    }

    @Test("Opening the pack screen checks again whether the account has to be relinked")
    func openingRechecksRelink() async throws {
        let relinkStatusProvider = RelinkStatusProviderStub()
        let sut = makeSUT(relinkStatusProvider: relinkStatusProvider)
        var refreshes = relinkStatusProvider.refreshes.makeAsyncIterator()

        sut.onWillAppear()
        await refreshes.next()
        try await stopPolling(sut)

        #expect(relinkStatusProvider.refreshesCount == 1)
    }

    @Test("Returning to the foreground on the pack screen checks the relink again")
    func foregroundRechecksRelink() async throws {
        let notificationCenter = NotificationCenterSpy()
        let relinkStatusProvider = RelinkStatusProviderStub()
        let sut = makeSUT(relinkStatusProvider: relinkStatusProvider, notificationCenter: notificationCenter)
        var refreshes = relinkStatusProvider.refreshes.makeAsyncIterator()

        sut.onWillAppear()
        await refreshes.next()
        try await notificationCenter.observation(of: .willEnterForeground)

        notificationCenter.post(.willEnterForeground)
        await refreshes.next()
        try await stopPolling(sut)

        #expect(relinkStatusProvider.refreshesCount == 2)
    }
}

// MARK: - Helpers

private extension CollectiblesMachineViewModelTests {
    func makeSUT(
        provider: (any CollectiblesMachineProvider)? = nil,
        relinkStatusProvider: (any CollectiblesRelinkStatusProvider)? = nil,
        isPurchaseLocked: @escaping @MainActor () -> Bool = { false },
        pollInterval: Duration = .seconds(60),
        notificationCenter: NotificationCenter = NotificationCenter()
    ) -> SUT {
        let sut = SUT(
            machineID: "pokemon_50",
            machine: Self.machine(),
            routable: nil,
            prizePoolProvider: PrizePoolProviderStub(),
            relinkStatusProvider: relinkStatusProvider,
            isPurchaseLocked: isPurchaseLocked,
            provider: provider ?? MachineProviderStub(results: [.success(Self.machine())]),
            pollInterval: pollInterval,
            notificationCenter: notificationCenter
        )
        return trackForMemoryLeaks(sut)
    }

    /// Waits for the loop to unwind so the leak check does not race the in-flight request.
    func stopPolling(_ sut: SUT) async throws {
        let task = sut.pollingTask
        sut.onWillDisappear()
        try await task?.waitForCompletion()
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
            artworkURL: URL(string: "https://example.com/pack.png"),
            price: price,
            platformFee: 1,
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

private final class RelinkStatusProviderStub: CollectiblesRelinkStatusProvider {
    let isRelinkRequiredSubject = CurrentValueSubject<Bool, Never>(false)
    let refreshes: AsyncStream<Void>

    private let refreshesContinuation: AsyncStream<Void>.Continuation
    private let refreshesCounter = OSAllocatedUnfairLock(initialState: 0)

    var refreshesCount: Int { refreshesCounter.withLock { $0 } }

    var isRelinkRequiredPublisher: AnyPublisher<Bool, Never> { isRelinkRequiredSubject.eraseToAnyPublisher() }
    var isRelinkingPublisher: AnyPublisher<Bool, Never> { Just(false).eraseToAnyPublisher() }

    init() {
        (refreshes, refreshesContinuation) = AsyncStream<Void>.makeStream()
    }

    func refreshStateSilently() async {
        refreshesCounter.withLock { $0 += 1 }
        refreshesContinuation.yield()
    }
}

/// The pool is not under test here, an empty page keeps its view model quiet.
private struct PrizePoolProviderStub: CollectiblesPrizePoolProvider {
    func load(machineID: String, page: Int) async throws -> CollectiblesPrizePoolPage {
        CollectiblesPrizePoolPage(prizes: [], hasNext: false)
    }
}

@MainActor
private final class MachineProviderStub: CollectiblesMachineProvider {
    let loads = TestSignal<Void>()

    var loadCallsCount: Int {
        loads.recorded.count
    }

    private var results: [Result<CollectiblesMachine, any Error>]

    /// The last result repeats once the script runs out, so an extra poll tick never crashes the test.
    init(results: [Result<CollectiblesMachine, any Error>]) {
        self.results = results
    }

    func load(id: String) async throws -> CollectiblesMachine {
        let result = results.count > 1 ? results.removeFirst() : results[0]
        loads.send()
        return try result.get()
    }
}
