//
//  GachaPacksMockProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct GachaPacksMockProvider: GachaPacksProvider {
    func load(loreID: String?) async throws -> [GachaPack] {
        try await Task.sleep(for: .milliseconds(600))

        guard let loreID else {
            return Self.packs
        }

        return Self.packs.filter { $0.loreID == loreID }
    }
}

// MARK: - Fixtures

private extension GachaPacksMockProvider {
    static let packs: [GachaPack] = GachaLoresMockProvider.lores.flatMap { lore in
        (1 ... lore.packsCount).map { index in
            makePack(lore: lore, index: index)
        }
    }

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
