//
//  GaslessTransactionsDTO+GaslessFeeTokensResult.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension GaslessTransactionsDTO.Response {
    struct FeeTokens: Decodable {
        let tokens: [FeeToken]

        private enum CodingKeys: String, CodingKey {
            case result
        }

        private enum ResultKeys: String, CodingKey {
            case tokens
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let result = try container.nestedContainer(keyedBy: ResultKeys.self, forKey: .result)
            tokens = try result.decode([FeeToken].self, forKey: .tokens)
        }
    }

    // [REDACTED_TODO_COMMENT]
    struct FeeToken: Decodable {
        let tokenAddress: String
        let tokenSymbol: String
        let tokenName: String
        let decimals: Int
        let chainId: Int?
        let chain: String

        private enum CodingKeys: String, CodingKey {
            case tokenAddress
            case tokenSymbol
            case tokenName
            case decimals
            case chainId
            case chain
            case address
            case symbol
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            tokenAddress = try container.decodeIfPresent(String.self, forKey: .tokenAddress)
                ?? container.decode(String.self, forKey: .address)
            tokenSymbol = try container.decodeIfPresent(String.self, forKey: .tokenSymbol)
                ?? container.decode(String.self, forKey: .symbol)
            tokenName = try container.decodeIfPresent(String.self, forKey: .tokenName) ?? tokenSymbol
            decimals = try container.decode(Int.self, forKey: .decimals)
            chainId = try container.decodeIfPresent(Int.self, forKey: .chainId)
            chain = try container.decode(String.self, forKey: .chain)
        }
    }
}
