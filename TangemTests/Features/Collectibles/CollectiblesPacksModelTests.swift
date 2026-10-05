//
//  CollectiblesPacksModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemTestKit
@testable import Tangem

@Suite("CollectiblesPacksModel")
@MainActor
final class CollectiblesPacksModelTests: LeakTrackingTestSuite {
    @Test("Stops paginating when the backend repeats the cursor")
    func stopsOnRepeatedCursor() async throws {
        let provider = PacksProviderMock()
        provider.results = [
            .success(Self.page(ids: ["pokemon_50"], hasNext: true, cursor: "stuck")),
            .success(Self.page(ids: ["pokemon_250"], hasNext: true, cursor: "stuck")),
        ]
        let sut = makeSUT(provider: provider)

        let firstPage = try await sut.load()
        #expect(firstPage.hasMore)

        let secondPage = try await sut.loadMore()

        #expect(!secondPage.hasMore)
        #expect(secondPage.packs.map(\.id) == ["pokemon_50", "pokemon_250"])
        #expect(provider.requests.map(\.cursor) == [nil, "stuck"])
    }

    @Test("Serves a switched-back lore from the cache with its pagination tail")
    func restoresLoreFromCache() async throws {
        let provider = PacksProviderMock()
        provider.results = [
            .success(Self.page(ids: ["pokemon_50"], hasNext: true, cursor: "page-2")),
            .success(Self.page(ids: ["sports_100"], hasNext: false, cursor: nil)),
        ]
        let sut = makeSUT(provider: provider)

        _ = sut.switchLore("pokemon")
        _ = try await sut.load()

        _ = sut.switchLore("sports")
        _ = try await sut.load()

        let cached = try #require(sut.switchLore("pokemon"))

        #expect(cached.packs.map(\.id) == ["pokemon_50"])
        #expect(cached.hasMore)
        #expect(provider.requests.count == 2)
    }
}

// MARK: - Helpers

private extension CollectiblesPacksModelTests {
    func makeSUT(provider: PacksProviderMock) -> CollectiblesPacksModel {
        trackForMemoryLeaks(CollectiblesPacksModel(provider: provider))
    }

    static func page(ids: [String], hasNext: Bool, cursor: String?) -> CollectiblesPacksPage {
        let packs = ids.map { id in
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

        return CollectiblesPacksPage(packs: packs, hasNext: hasNext, cursor: cursor)
    }
}

// MARK: - Mocks

@MainActor
private final class PacksProviderMock: CollectiblesPacksProvider {
    var results: [Result<CollectiblesPacksPage, Error>] = []
    private(set) var requests: [(loreID: String?, cursor: String?)] = []

    func load(loreID: String?, query: String, cursor: String?) async throws -> CollectiblesPacksPage {
        requests.append((loreID, cursor))
        return try results.removeFirst().get()
    }
}
