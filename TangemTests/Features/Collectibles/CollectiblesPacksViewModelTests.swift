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
}

// MARK: - Helpers

private extension CollectiblesPacksViewModelTests {
    func makeSUT(packSelectionHandler: @escaping (CollectiblesPack) -> Void) -> SUT {
        let sut = SUT(
            model: CollectiblesPacksModel(provider: PacksProviderStub()),
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
