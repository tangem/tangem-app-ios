//
//  NEARTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore
import BigInt

final class NEARTransactionBuilder {
    private var coinType: CoinType { .near }

    func buildForSign(transaction: Transaction) throws -> Data {
        let input = try buildInput(transaction: transaction)
        let txInputData = try input.serializedData()

        guard !txInputData.isEmpty else {
            throw BlockchainSdkError.failedToBuildTx
        }

        let preImageHashes = TransactionCompiler.preImageHashes(coinType: coinType, txInputData: txInputData)
        let output = try TxCompilerPreSigningOutput(serializedData: preImageHashes)

        guard output.error == .ok else {
            throw BlockchainSdkError.failedToBuildTx
        }

        return output.dataHash
    }

    func buildForSend(transaction: Transaction, signature: Data) throws -> Data {
        guard let transactionParams = transaction.params as? NEARTransactionParams else {
            throw BlockchainSdkError.failedToBuildTx
        }

        let input = try buildInput(transaction: transaction)
        let txInputData = try input.serializedData()

        guard !txInputData.isEmpty else {
            throw BlockchainSdkError.failedToBuildTx
        }

        let compiledTransaction = TransactionCompiler.compileWithSignatures(
            coinType: coinType,
            txInputData: txInputData,
            signatures: signature.asDataVector(),
            publicKeys: transactionParams.publicKey.blockchainKey.asDataVector()
        )
        let output = try NEARSigningOutput(serializedData: compiledTransaction)

        guard output.error == .ok else {
            throw BlockchainSdkError.failedToBuildTx
        }

        let serializedData = output.signedTransaction

        guard !serializedData.isEmpty else {
            throw BlockchainSdkError.failedToBuildTx
        }

        return serializedData
    }

    private func buildInput(transaction: Transaction) throws -> NEARSigningInput {
        guard let transactionParams = transaction.params as? NEARTransactionParams else {
            throw BlockchainSdkError.failedToBuildTx
        }

        let deposit = try depositPayload(from: transaction.amount)

        return NEARSigningInput.with { input in
            input.publicKey = transactionParams.publicKey.blockchainKey
            input.signerID = transaction.sourceAddress
            input.receiverID = transaction.destinationAddress
            input.blockHash = transactionParams.recentBlockHash.base58DecodedData
            input.nonce = UInt64(transactionParams.currentNonce + 1)
            input.actions = [
                NEARAction.with { action in
                    action.transfer = NEARTransfer.with { transfer in
                        transfer.deposit = deposit
                    }
                },
            ]
        }
    }

    /// Converts given amount to a uint128 with little-endian byte order.
    private func depositPayload(from amount: Amount) throws -> Data {
        let decimalValue = amount.value * pow(Decimal(10), amount.decimals)

        guard let bigUIntValue = BigUInt(decimal: decimalValue) else {
            throw BlockchainSdkError.failedToBuildTx
        }

        let rawPayload = Data(bigUIntValue.serialize().reversed())

        return rawPayload.trailingZeroPadding(toLength: 16)
    }
}
