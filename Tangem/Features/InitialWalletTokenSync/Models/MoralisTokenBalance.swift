//
//  MoralisTokenBalance.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation

struct MoralisTokenBalance: Equatable {
    let contractAddress: String?
    let symbol: String
    let name: String
    let decimals: Int
    let amount: Decimal
    let isNativeToken: Bool
}
