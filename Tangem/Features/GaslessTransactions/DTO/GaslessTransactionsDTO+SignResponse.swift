//
//  GaslessTransactionsDTO+SignResponse.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

extension GaslessTransactionsDTO.Response {
    struct SignResponse: Decodable {
        let result: Result

        struct Result: Decodable {
            let signedTransaction: String
            let gasLimit: String
            let maxFeePerGas: String
            let maxPriorityFeePerGas: String
        }
    }
}
