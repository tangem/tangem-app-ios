//
//  CollectiblesDTO+Machine.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension CollectiblesDTO {
    /// A machine (pack) as served by GET api/v1/machine/machines and GET api/v1/machine/{externalId}.
    struct Machine: Decodable {
        let id: String
        let externalId: String
        let name: String
        let shortName: String
        let price: Decimal
        let fee: Decimal
        let feeAmount: Decimal
        let contains: Int?
        let instantBuybackPercent: Int
        let lowThreshold: Int
        /// Drop chance per rarity tier, in percent.
        let odds: Tiers<Int>
        /// Card value range per rarity tier.
        let tierRanges: Tiers<TierRange>
        /// Remaining card count per rarity tier.
        let stock: Tiers<Int>
        let expectedValue: Decimal
        let image: String?
        let categoryId: String
        let createdAt: String
        let updatedAt: String
    }
}

extension CollectiblesDTO.Machine {
    struct Tiers<Value: Decodable>: Decodable {
        let common: Value?
        let uncommon: Value?
        let rare: Value?
        let epic: Value?
        let legendary: Value?
    }

    struct TierRange: Decodable {
        let start, end: Int
    }
}
