//
//  CollectiblesWonCard.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct CollectiblesWonCard {
    let nftAddress: String?
    let imageFrontURL: URL?
    let imageBackURL: URL?
    let gradingCompany: String?
    let grade: String?
    let gradingID: String?
    let rarity: CollectiblesMachine.Tier?
    let year: String?
    let set: String?
    let serialNumber: String?
    /// Insured value in dollars.
    let insuredValue: Decimal?
}
