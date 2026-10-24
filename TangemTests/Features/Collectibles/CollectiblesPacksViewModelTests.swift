//
//  CollectiblesPacksViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemTestKit
@testable import Tangem

@Suite("CollectiblesPacksViewModel", .serialized)
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

    @Test("A pull-to-refresh keeps the shown packs until the new page arrives", .timeLimit(.minutes(1)))
    func refreshKeepsPacksWhilePending() async {
        let provider = SuspendingPacksProvider()
        let sut = makeSUT(provider: provider)

        let refresh = Task { await sut.refresh() }
        await waitUntil { provider.loadCallsCount == 1 }

        #expect(sut.state.isContentLoaded)

        provider.resume(with: CollectiblesPacksPage(packs: [Self.packs()[0]], hasNext: false, cursor: nil))
        await refresh.value

        guard case .content(let models) = sut.state else {
            Issue.record("Expected the refreshed packs, got \(sut.state)")
            return
        }

        #expect(models.map(\.id) == ["pokemon_50"])
    }
}

// MARK: - Helpers

private extension CollectiblesPacksViewModelTests {
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

    func waitUntil(_ condition: @MainActor () -> Bool) async {
        for _ in 0 ..< 100 where !condition() {
            await Task.yield()
        }
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
    private(set) var loadCallsCount = 0

    private var continuation: CheckedContinuation<CollectiblesPacksPage, any Error>?

    func load(loreID: String?, query: String, cursor: String?) async throws -> CollectiblesPacksPage {
        loadCallsCount += 1

        return try await withCheckedThrowingContinuation { continuation = $0 }
    }

    func resume(with page: CollectiblesPacksPage) {
        continuation?.resume(returning: page)
        continuation = nil
    }
}
