//
//  MoralisTokenBalanceDTO.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum MoralisTokenBalanceDTO {}

extension MoralisTokenBalanceDTO {
    struct Response: Decodable {
        let result: [TokenBalance]
        let page: Int?
        let pageSize: Int?
        let blockNumber: Int?
        let cursor: String?
    }

    struct TokenBalance: Decodable {
        let name: String
        let symbol: String
        let decimals: Int
        let balance: String
        let balanceFormatted: String
        let nativeToken: Bool
        let tokenAddress: String?
    }
}
