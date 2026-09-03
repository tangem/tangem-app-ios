//
//  GachaPacksMockProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct GachaPacksMockProvider: GachaPacksProvider {
    private static let packs: [GachaPack] = GachaLoresMockProvider.lores.flatMap { lore in
        (1 ... lore.packsCount).map { index in
            makePack(lore: lore, index: index)
        }
    }

    func load(loreID: String?, query: String) async throws -> [GachaPack] {
        try await Task.sleep(for: .seconds(1.5))

        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

        return Self.packs.filter { pack in
            let matchesLore = loreID.map { pack.loreID == $0 } ?? true
            let matchesQuery = trimmedQuery.isEmpty || pack.name.localizedCaseInsensitiveContains(trimmedQuery)

            return matchesLore && matchesQuery
        }
    }
}

// MARK: - Fixtures

private extension GachaPacksMockProvider {
    static func makePack(lore: GachaLore, index: Int) -> GachaPack {
        let tiers = ["Legendary", "Water", "Elite"]
        let tier = tiers[(index - 1) % tiers.count]
        let price = Decimal(50 * (1 + (index - 1) % 4))

        return GachaPack(
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
