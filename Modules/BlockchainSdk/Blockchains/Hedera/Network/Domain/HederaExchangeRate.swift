//
//  HederaExchangeRate.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

/// The amount of HBAR per 1 USD ('reverse' exchange rate) for the current and next blocks, respectively.
struct HederaExchangeRate {
    let currentHBARPerUSD: Decimal
    let nextHBARPerUSD: Decimal

    var maxHBARPerUSD: Decimal {
        max(currentHBARPerUSD, nextHBARPerUSD)
    }
}
