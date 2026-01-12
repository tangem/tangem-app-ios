//
//  GaslessTransactionsDTO+MetaTransaction.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

extension GaslessTransactionsDTO.Request {
    struct MetaTransaction: Encodable, Equatable {
        let transactionData: TransactionData
        let signature: String
        let userAddress: String
        let chainId: BigUInt
        let eip7702auth: EIP7702Auth

        struct TransactionData: Encodable, Equatable {
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
            let chainId: BigUInt
            let address: String
            let nonce: String
            let yParity: BigUInt
            let r: String
            let s: String
        }
    }
}

// MARK: - Pretty Printed Debug JSON

extension GaslessTransactionsDTO.Request.MetaTransaction {
    func prettyPrinted() -> String {
        """
        GASLESSDEBUG
        ========================================================
        {
          "gaslessTransaction": \(transactionData.prettyPrinted),
          "signature": "\(signature)",
          "userAddress": "\(userAddress)",
          "chainId": \(chainId),
          "eip7702auth": \(eip7702auth.prettyPrinted)
        }
        ========================================================
        """
    }
}

extension GaslessTransactionsDTO.Request.MetaTransaction.TransactionData {
    var prettyPrinted: String {
        """
        {
          "transaction": \(transaction.prettyPrinted),
          "fee": \(fee.prettyPrinted),
          "nonce": "\(nonce)"
        }
        """
    }
}

extension GaslessTransactionsDTO.Request.MetaTransaction.TransactionData.Transaction {
    var prettyPrinted: String {
        """
        {
          "to": "\(to)",
          "value": "\(value)",
          "data": "\(data)"
        }
        """
    }
}

extension GaslessTransactionsDTO.Request.MetaTransaction.TransactionData.Fee {
    var prettyPrinted: String {
        """
        {
          "feeToken": "\(feeToken)",
          "maxTokenFee": "\(maxTokenFee)",
          "coinPriceInToken": "\(coinPriceInToken)",
          "feeTransferGasLimit": "\(feeTransferGasLimit)",
          "baseGas": "\(baseGas)"
        }
        """
    }
}

extension GaslessTransactionsDTO.Request.MetaTransaction.EIP7702Auth {
    var prettyPrinted: String {
        """
        {
          "chainId": \(chainId),
          "address": "\(address)",
          "nonce": "\(nonce)",
          "yParity": \(yParity),
          "r": "\(r)",
          "s": "\(s)"
        }
        """
    }
}
