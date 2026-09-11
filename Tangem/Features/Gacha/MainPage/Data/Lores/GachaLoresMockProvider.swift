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
        GachaLore(id: "sports", title: "Sports", packsCount: 8),
        GachaLore(id: "pokemon", title: "Pokemon", packsCount: 12),
        GachaLore(id: "anime", title: "Anime", packsCount: 7),
        GachaLore(id: "one-piece", title: "One Piece", packsCount: 5),
    ]

    func load() async throws -> [GachaLore] {
        try await Task.sleep(for: .milliseconds(600))

        return Self.lores
    }
}
