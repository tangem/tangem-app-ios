//
//  MoralisTokenBalanceDTO.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation

enum MoralisTokenBalanceDTO {}

extension MoralisTokenBalanceDTO {
    struct Response: Decodable {
        let result: [TokenBalance]
        let page: String?
        let pageSize: String?
        let blockNumber: String?
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
