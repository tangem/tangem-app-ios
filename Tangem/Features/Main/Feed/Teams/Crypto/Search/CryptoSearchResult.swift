//
//  CryptoSearchResult.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemUI

struct CryptoSearchResult: Identifiable, Hashable {
    let id: String
    let name: String
    let symbol: String
    let price: String
    let change: String
    let isPositive: Bool
    let icon: TokenIconInfo
    let model: MarketsTokenModel

    static func == (lhs: CryptoSearchResult, rhs: CryptoSearchResult) -> Bool {
        lhs.id == rhs.id && lhs.price == rhs.price && lhs.change == rhs.change
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
