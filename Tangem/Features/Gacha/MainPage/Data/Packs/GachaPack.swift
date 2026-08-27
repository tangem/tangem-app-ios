//
//  GachaPack.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct GachaPack {
    let id: String
    let name: String
    let loreID: String
    let price: Decimal
    let currencyCode: String
    /// Kept per pack because the partner quotes it per machine — never hardcode a rate.
    let buybackRate: Decimal?
    let artworkURL: URL?
}
