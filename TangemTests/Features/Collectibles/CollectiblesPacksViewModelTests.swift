//
//  CollectiblesPacksViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import Testing
import TangemFoundation
import TangemTestKit
@testable import Tangem

@Suite("CollectiblesPacksViewModel", .timeLimit(.minutes(1)))
@MainActor
final class CollectiblesPacksViewModelTests: LeakTrackingTestSuite {
    typealias SUT = CollectiblesPacksViewModel

    @Test("Selecting a displayed pack hands it to the selection handler")
    func selectsDisplayedPack() {
        var selectedPack: CollectiblesPack?
        let sut = makeSUT { selectedPack = $0 }

        sut.selectPack(withID: "pokemon_250")

        #expect(selectedPack?.id == "pokemon_250")
    }

    @Test("Selecting an unknown pack id leaves the handler untouched")
    func ignoresUnknownPackID() {
        var selectedPack: CollectiblesPack?
        let sut = makeSUT { selectedPack = $0 }

        sut.selectPack(withID: "missing")

        #expect(selectedPack == nil)
    }

    @Test("A pull-to-refresh keeps the shown packs until the new page arrives")
    func refreshKeepsPacksWhilePending() async throws {
        let provider = SuspendingPacksProvider()
        let sut = makeSUT(provider: provider)

        let refresh = Task { await sut.refresh() }
        try await provider.loads.next()

        #expect(sut.state.isContentLoaded)

        provider.resume(with: CollectiblesPacksPage(packs: [Self.packs()[0]], hasNext: false, cursor: nil))
        try await refresh.waitForCompletion()

        guard case .content(let models) = sut.state else {
            Issue.record("Expected the refreshed packs, got \(sut.state)")
            return
        }

        #expect(models.map(\.id) == ["pokemon_50"])
    }

    // MARK: - Lore switch

    @Test("An uncached lore switch keeps the shown packs dimmed until the new page arrives")
    func loreSwitchKeepsPacksWhileReloading() async throws {
        let provider = SuspendingPacksProvider()
        let sut = makeSUT(provider: provider)

        sut.reload(loreID: Constants.otherLoreID)
        try await provider.loads.next()

        guard case .reloading(.content(let shownModels)) = sut.state else {
            Issue.record("Expected the previous packs kept while reloading, got \(sut.state)")
            return
        }

        #expect(shownModels.map(\.id) == ["pokemon_50", "pokemon_250"])

        provider.resume(with: CollectiblesPacksPage(packs: [Self.packs()[0]], hasNext: false, cursor: nil))
        await sut.$state.firstValue { !$0.isReloading }

        guard case .content(let models) = sut.state else {
            Issue.record("Expected the new lore's packs, got \(sut.state)")
            return
        }

        #expect(models.map(\.id) == ["pokemon_50"])
    }

    @Test("A failed uncached lore switch stops dimming and shows the failure")
    func failedLoreSwitchStopsReloading() async throws {
        let provider = SuspendingPacksProvider()
        let sut = makeSUT(provider: provider)

        sut.reload(loreID: Constants.otherLoreID)
        try await provider.loads.next()

        provider.fail(with: URLError(.notConnectedToInternet))
        await sut.$state.firstValue { $0.isFailed }

        #expect(sut.state.isFailed)
    }
}

// MARK: - Helpers

private extension CollectiblesPacksViewModelTests {
    enum Constants {
        static let otherLoreID = "sports"
    }

    func makeSUT(
        provider: any CollectiblesPacksProvider = PacksProviderStub(),
        packSelectionHandler: @escaping (CollectiblesPack) -> Void = { _ in }
    ) -> SUT {
        let sut = SUT(
            model: CollectiblesPacksModel(provider: provider),
            packSelectionHandler: packSelectionHandler
        )
        sut.show(CollectiblesPacksModel.Snapshot(packs: Self.packs(), cursor: nil, hasMore: false))

        return trackForMemoryLeaks(sut)
    }

    static func packs() -> [CollectiblesPack] {
        ["pokemon_50", "pokemon_250"].map { id in
            CollectiblesPack(
                id: id,
                loreID: "pokemon",
                currencyCode: "USD",
                machine: CollectiblesMachine(
                    name: id.uppercased(),
                    artworkURL: nil,
                    price: 50,
                    platformFee: 1,
                    cardsPerPack: 1,
                    buybackRate: 0.85,
                    expectedValue: 55,
                    tiers: []
                )
            )
        }
    }
}

// MARK: - Stubs

private struct PacksProviderStub: CollectiblesPacksProvider {
    func load(loreID: String?, query: String, cursor: String?) async throws -> CollectiblesPacksPage {
        throw URLError(.unsupportedURL)
    }
}

@MainActor
private final class SuspendingPacksProvider: CollectiblesPacksProvider {
    let loads = TestSignal<Void>()

    private let continuation = OSAllocatedUnfairLock<CheckedContinuation<CollectiblesPacksPage, any Error>?>(initialState: nil)

    func load(loreID: String?, query: String, cursor: String?) async throws -> CollectiblesPacksPage {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation.withLock { $0 = continuation }
            loads.send()
        }
    }

    func resume(with page: CollectiblesPacksPage) {
        pendingContinuation()?.resume(returning: page)
    }

    func fail(with error: any Error) {
        pendingContinuation()?.resume(throwing: error)
    }

    private func pendingContinuation() -> CheckedContinuation<CollectiblesPacksPage, any Error>? {
        continuation.withLock { continuation in
            defer { continuation = nil }
            return continuation
        }
    }
}
