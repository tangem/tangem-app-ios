//
//  GachaLoresMockProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct GachaLoresMockProvider: GachaLoresProvider {
    func load() async throws -> [GachaLore] {
        try await Task.sleep(for: .milliseconds(600))

        return [
            GachaLore(id: "sports", title: "Sports", packsCount: 8),
            GachaLore(id: "pokemon", title: "Pokemon", packsCount: 12),
            GachaLore(id: "anime", title: "Anime", packsCount: 7),
            GachaLore(id: "one-piece", title: "One Piece", packsCount: 5),
        ]
    }
}
