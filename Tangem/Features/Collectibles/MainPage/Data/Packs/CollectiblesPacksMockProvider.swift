//
//  CollectiblesPacksMockProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct CollectiblesPacksMockProvider: CollectiblesPacksProvider {
    private static let packs: [CollectiblesPack] = CollectiblesLoresMockProvider.lores.flatMap { lore in
        (1 ... lore.packsCount).map { index in
            makePack(lore: lore, index: index)
        }
    }

    func load(loreID: String?, query: String, cursor: String?) async throws -> CollectiblesPacksPage {
        try await Task.sleep(for: .seconds(1.5))

        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

        let packs = Self.packs.filter { pack in
            let matchesLore = loreID.map { pack.loreID == $0 } ?? true
            let matchesQuery = trimmedQuery.isEmpty || pack.name.localizedCaseInsensitiveContains(trimmedQuery)

            return matchesLore && matchesQuery
        }

        return CollectiblesPacksPage(packs: packs, hasNext: false, cursor: nil)
    }
}

// MARK: - Fixtures

private extension CollectiblesPacksMockProvider {
    static func makePack(lore: CollectiblesLore, index: Int) -> CollectiblesPack {
        let tiers = ["Legendary", "Water", "Elite"]
        let tier = tiers[(index - 1) % tiers.count]
        let price = Decimal(50 * (1 + (index - 1) % 4))

        return CollectiblesPack(
            id: "\(lore.id)-\(index)",
            name: "\(tier) \(index)",
            loreID: lore.id,
            price: price,
            currencyCode: "USD",
            buybackRate: 0.85,
            artworkURL: nil
        )
    }
}
