//
//  CollectiblesMachine.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct CollectiblesMachine {
    let name: String
    let artworkURL: URL?
    let price: Decimal
    let platformFee: Decimal
    let cardsPerPack: Int?
    let buybackRate: Decimal
    /// Average card value in dollars; drifts in near-real time as the stock changes.
    let expectedValue: Decimal
    /// Only the tiers this machine actually carries, in rarity order.
    let tiers: [TierStats]
    var openingVideoURL: URL?
}

extension CollectiblesMachine {
    enum Tier: String, CaseIterable {
        case common
        case uncommon
        case rare
        case epic
        case legendary
    }

    struct TierStats {
        let tier: Tier
        /// Drop chance as a fraction (0.8 is 80%).
        let odds: Decimal?
        /// Card value range in dollars.
        let valueRange: ClosedRange<Decimal>?
    }
}
