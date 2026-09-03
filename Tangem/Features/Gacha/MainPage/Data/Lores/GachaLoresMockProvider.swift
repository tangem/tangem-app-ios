//
//  GachaLoresMockProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct GachaLoresMockProvider: GachaLoresProvider {
    /// Shared with the packs mock so the tab counters match the grid contents.
    static let lores: [GachaLore] = [
        // Deliberately lopsided: switching between a long and a one-pack lore makes the grid's behaviour visible.
        GachaLore(id: "sports", title: "Sports", packsCount: 3),
        GachaLore(id: "pokemon", title: "Pokemon", packsCount: 2),
        GachaLore(id: "anime", title: "Anime", packsCount: 1),
        GachaLore(id: "one-piece", title: "One Piece", packsCount: 12),
    ]

    func load() async throws -> [GachaLore] {
        try await Task.sleep(for: .seconds(1.5))

        return Self.lores
    }
}
