//
//  MoralisTokenBalance.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct MoralisTokenBalance: Equatable, Sendable {
    let contractAddress: String?
    let symbol: String
    let name: String
    let decimals: Int
    let amount: Decimal
    let isNativeToken: Bool
}
