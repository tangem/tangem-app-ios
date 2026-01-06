//
//  GaslessTransactionsDTO+GaslessFeeTokensResult.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension GaslessTransactionsDTO.Response {
    struct GaslessFeeTokensResult: Decodable {
        let tokens: [FeeToken]
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
