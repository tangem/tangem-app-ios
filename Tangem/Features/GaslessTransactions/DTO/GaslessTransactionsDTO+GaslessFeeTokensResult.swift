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

    struct FeeToken: Decodable {
        let tokenAddress: String
        let tokenSymbol: String
        let tokenName: String
        let decimals: Int
        let chainId: Int
        let chain: String
    }
}
