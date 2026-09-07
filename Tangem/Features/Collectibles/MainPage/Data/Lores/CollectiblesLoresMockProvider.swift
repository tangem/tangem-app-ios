//
//  CollectiblesLoresMockProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct CollectiblesLoresMockProvider: CollectiblesLoresProvider {
    /// Shared with the packs mock so the tab counters match the grid contents.
    static let lores: [CollectiblesLore] = [
        // Deliberately lopsided: switching between a long and a one-pack lore makes the grid's behaviour visible.
        CollectiblesLore(id: "sports", title: "Sports", packsCount: 3),
        CollectiblesLore(id: "pokemon", title: "Pokemon", packsCount: 2),
        CollectiblesLore(id: "anime", title: "Anime", packsCount: 1),
        CollectiblesLore(id: "one-piece", title: "One Piece", packsCount: 12),
    ]

    func load() async throws -> CollectiblesLoreCatalogue {
        try await Task.sleep(for: .seconds(1.5))

        return CollectiblesLoreCatalogue(lores: Self.lores, totalPacksCount: Self.lores.sum(by: \.packsCount))
    }
}
