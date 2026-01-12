//
//  GaslessTransactionsEIP712Util.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

extension GaslessTransactionBuilder {
    struct GaslessTransactionsEIP712Util {
        let domainName = "Tangem7702GaslessExecutor"
        let domainVersion = "1"
        let primaryType = "GaslessTransaction"

        // MARK: - Public Implementation

        func makeGaslessTypedData(
            transaction: GaslessTransactionsDTO.Request.MetaTransaction.TransactionData.Transaction,
            fee: GaslessTransactionsDTO.Request.MetaTransaction.TransactionData.Fee,
            nonce: String,
            chainId: String,
            verifyingContract: String
        ) -> EIP712TypedData {
            let types: [String: [EIP712Type]] = [
                "EIP712Domain": [
                    .init(name: "name", type: "string"),
                    .init(name: "version", type: "string"),
                    .init(name: "chainId", type: "uint256"),
                    .init(name: "verifyingContract", type: "address"),
                ],
                "Transaction": [
                    .init(name: "to", type: "address"),
                    .init(name: "value", type: "uint256"),
                    .init(name: "data", type: "bytes"),
                ],
                "Fee": [
                    .init(name: "feeToken", type: "address"),
                    .init(name: "maxTokenFee", type: "uint256"),
                    .init(name: "coinPriceInToken", type: "uint256"),
                    .init(name: "feeTransferGasLimit", type: "uint256"),
                    .init(name: "baseGas", type: "uint256"),
                ],
                primaryType: [
                    .init(name: "transaction", type: "Transaction"),
                    .init(name: "fee", type: "Fee"),
                    .init(name: "nonce", type: "uint256"),
                ],
            ]

            let domain: JSON = .object([
                "name": .string(domainName),
                "version": .string(domainVersion),
                "chainId": .string(chainId),
                "verifyingContract": .string(verifyingContract),
            ])

            let message: JSON = .object([
                "transaction": .object([
                    "to": .string(transaction.to),
                    "value": .string(transaction.value),
                    "data": .string(transaction.data),
                ]),
                "fee": .object([
                    "feeToken": .string(fee.feeToken),
                    "maxTokenFee": .string(fee.maxTokenFee),
                    "coinPriceInToken": .string(fee.coinPriceInToken),
                    "feeTransferGasLimit": .string(fee.feeTransferGasLimit),
                    "baseGas": .string(fee.baseGas),
                ]),
                "nonce": .string(nonce),
            ])

            return EIP712TypedData(types: types, primaryType: primaryType, domain: domain, message: message)
        }
    }
}
