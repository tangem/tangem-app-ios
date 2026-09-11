//
//  EarnApyInfo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// `apy` is a fraction (0.05 = 5%).
struct EarnApyInfo: Equatable {
    let isActive: Bool
    let apy: Decimal
    /// APR or APY — the row label must not promise compounding the product does not do.
    let rateType: RateType
    let product: Product

    /// Reserved for the upcoming tap-routing.
    enum Product: Equatable {
        case staking
        case yieldSupply
    }
}
