//
//  GaslessTransactionsDTO+GaslessTransaction.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension GaslessTransactionsDTO.Request {
    struct GaslessTransaction: Encodable, Equatable {
        let gaslessTransaction: TransactionData
        let signature: String
        let userAddress: String
        let chainId: Int
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
                let feeReceiver: String
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

// MARK: - Pretty Printed Debug JSON

extension GaslessTransactionsDTO.Request.GaslessTransaction {
    func prettyPrinted() -> String {
        """
        GASLESSDEBUG
        ========================================================
        {
          "gaslessTransaction": \(gaslessTransaction.prettyPrinted),
          "signature": "\(signature)",
          "userAddress": "\(userAddress)",
          "chainId": \(chainId),
          "eip7702auth": \(eip7702auth.prettyPrinted)
        }
        ========================================================
        """
    }
}

extension GaslessTransactionsDTO.Request.GaslessTransaction.TransactionData {
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

extension GaslessTransactionsDTO.Request.GaslessTransaction.TransactionData.Transaction {
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

extension GaslessTransactionsDTO.Request.GaslessTransaction.TransactionData.Fee {
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

extension GaslessTransactionsDTO.Request.GaslessTransaction.EIP7702Auth {
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
