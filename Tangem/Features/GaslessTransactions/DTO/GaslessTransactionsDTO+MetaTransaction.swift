//
//  GaslessTransactionsDTO+MetaTransaction.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension GaslessTransactionsDTO.Request {
    struct MetaTransaction: Encodable, Equatable {
        let gaslessTransaction: GaslessTransaction
        let signature: String
        let userAddress: String
        let chainId: Int
        let eip7702auth: EIP7702Auth

        struct GaslessTransaction: Encodable, Equatable {
            let transaction: Transaction
            let fee: Fee
            let nonce: String

            struct Transaction: Encodable, Equatable {
                let to: String
                let value: String
                let data: String
            }

            struct Fee: Encodable, Equatable {
                let feeToken: String
                let maxTokenFee: String
                let coinPriceInToken: String
                let feeTransferGasLimit: String
                let baseGas: String
            }
        }

        struct EIP7702Auth: Encodable, Equatable {
            let chainId: Int
            let address: String
            let nonce: String
            let yParity: Int
            let r: String
            let s: String
        }
    }
}
