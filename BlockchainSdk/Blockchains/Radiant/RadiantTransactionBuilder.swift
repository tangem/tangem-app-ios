//
//  RadiantCashTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import WalletCore
import TangemFoundation

class RadiantTransactionBuilder {
    private let walletPublicKey: Data
    private let unspentOutputManager: UnspentOutputManager
    private let decimalValue: Decimal

    private let scriptUtils = RadiantScriptUtils()

    // MARK: - Init

    init(walletPublicKey: Data, unspentOutputManager: UnspentOutputManager, decimalValue: Decimal) throws {
        self.walletPublicKey = try Secp256k1Key(with: walletPublicKey).compress()
        self.unspentOutputManager = unspentOutputManager
        self.decimalValue = decimalValue
    }

    // MARK: - Implementation

    func buildForSign(transaction: Transaction) throws -> [Data] {
        let unspents = unspentOutputManager.allOutputs()

        let txForPreimage = UnspentTransaction(
            decimalValue: decimalValue,
            amount: transaction.amount,
            fee: transaction.fee,
            unspents: unspents
        )

        let hashes = try unspents.enumerated().map { index, _ in
            let preImageHash = try buildPreImageHashes(
                with: txForPreimage,
                targetAddress: transaction.destinationAddress,
                sourceAddress: transaction.sourceAddress,
                index: index
            )

            return preImageHash.getDoubleSha256()
        }

        return hashes
    }

    func buildForSend(transaction: Transaction, signatures: [Data]) throws -> Data {
        let outputScripts = try scriptUtils.buildSignedScripts(
            signatures: signatures,
            publicKey: walletPublicKey,
            isDer: false
        )

        let unspents = buildUnspents(signedOutputScripts: outputScripts)

        let txForSigned = UnspentTransaction(
            decimalValue: decimalValue,
            amount: transaction.amount,
            fee: transaction.fee,
            unspents: unspents
        )

        let rawTransaction = try buildRawTransaction(
            with: txForSigned,
            targetAddress: transaction.destinationAddress,
            changeAddress: transaction.changeAddress,
            index: nil
        )

        return rawTransaction
    }

    func estimateTransactionSize(transaction: Transaction) throws -> Int {
        let hashesForSign = try buildForSign(transaction: transaction)
        let signaturesForSend = hashesForSign.map { _ in Data([UInt8](repeating: UInt8(0x01), count: 64)) }
        let rawTransaction = try buildForSend(transaction: transaction, signatures: signaturesForSend)

        return rawTransaction.count
    }

    // MARK: - Build Transaction Data

    /// Build preimage hashes for sign transaction with specify Radiant blockchain (etc. HashOutputHashes)
    /// - Parameters:
    ///   - tx: Union of unspents amount & change transaction
    ///   - targetAddress
    ///   - sourceAddress
    ///   - index: position image for output
    /// - Returns: Hash of one preimage
    private func buildPreImageHashes(
        with tx: UnspentTransaction,
        targetAddress: String,
        sourceAddress: String,
        index: Int
    ) throws -> Data {
        var txToSign = Data()

        // version
        txToSign.append(contentsOf: [UInt8(0x01), UInt8(0x00), UInt8(0x00), UInt8(0x00)])

        // hashPrevouts
        scriptUtils.writePrevoutHash(tx.unspents, into: &txToSign)

        // hashSequence
        scriptUtils.writeSequenceHash(tx.unspents, into: &txToSign)

        // outpoint
        let currentOutput = tx.unspents[index]
        txToSign.append(contentsOf: currentOutput.hash.reversed())
        txToSign.append(contentsOf: currentOutput.index.bytes4LE)

        // scriptCode of the input (serialized as scripts inside CTxOuts)
        let scriptCode = scriptUtils.buildOutputScript(address: sourceAddress)

        txToSign.append(scriptCode.count.byte)
        txToSign.append(contentsOf: scriptCode)

        // value of the output spent by this input (8-byte little endian)
        txToSign.append(contentsOf: currentOutput.amount.bytes8LE)

        // nSequence of the input (4-byte little endian), ffffffff only
        txToSign.append(contentsOf: [UInt8(0xff), UInt8(0xff), UInt8(0xff), UInt8(0xff)])

        // hashOutputHashes (32-byte hash)
        try scriptUtils.writeHashOutputHashes(
            amount: tx.amountSatoshiDecimalValue,
            sourceAddress: sourceAddress,
            targetAddress: targetAddress,
            change: tx.changeSatoshiDecimalValue,
            into: &txToSign
        )

        // hashOutputs (32-byte hash)
        try scriptUtils.writeHashOutput(
            amount: tx.amountSatoshiDecimalValue,
            sourceAddress: sourceAddress,
            targetAddress: targetAddress,
            change: tx.changeSatoshiDecimalValue,
            into: &txToSign
        )

        // nLocktime of the transaction (4-byte little endian)
        txToSign.append(contentsOf: [UInt8(0x00), UInt8(0x00), UInt8(0x00), UInt8(0x00)])

        // sighash type of the signature (4-byte little endian)
        txToSign.append(contentsOf: [UInt8(0x41), UInt8(0x00), UInt8(0x00), UInt8(0x00)])

        return txToSign
    }

    /// Build raw transaction data without specify Radiant blockchain (etc. BitcoinCash)
    /// - Parameters:
    ///   - tx: Union of unspents amount & change transaction
    ///   - targetAddress
    ///   - changeAddress
    ///   - index: index of input transaction (specify nil value)
    /// - Returns: Raw transaction data
    private func buildRawTransaction(
        with tx: UnspentTransaction,
        targetAddress: String,
        changeAddress: String,
        index: Int?
    ) throws -> Data {
        var txBody = Data()

        // version
        txBody.append(contentsOf: [UInt8(0x01), UInt8(0x00), UInt8(0x00), UInt8(0x00)])

        // 01
        txBody.append(tx.unspents.count.byte)

        // hex str hash prev btc
        for (inputIndex, input) in tx.unspents.enumerated() {
            let hashKey: [UInt8] = input.hash.reversed()
            txBody.append(contentsOf: hashKey)
            txBody.append(contentsOf: input.index.bytes4LE)

            if (index == nil) || (inputIndex == index) {
                txBody.append(input.script.count.byte)
                txBody.append(contentsOf: input.script)
            } else {
                txBody.append(UInt8(0x00))
            }

            // ffffffff
            txBody.append(contentsOf: [UInt8(0xff), UInt8(0xff), UInt8(0xff), UInt8(0xff)]) // sequence
        }

        // 02
        let outputCount = tx.changeSatoshiDecimalValue == 0 ? 1 : 2
        txBody.append(outputCount.byte)

        // 8 bytes
        txBody.append(contentsOf: tx.amountSatoshiDecimalValue.bytes8LE)

        let outputScriptBytes = scriptUtils.buildOutputScript(address: targetAddress)

        // hex str 1976a914....88ac
        txBody.append(outputScriptBytes.count.byte)
        txBody.append(contentsOf: outputScriptBytes)

        if tx.changeSatoshiDecimalValue != 0 {
            // 8 bytes of change satoshi value
            txBody.append(contentsOf: tx.changeSatoshiDecimalValue.bytes8LE)

            let outputScriptChangeBytes = scriptUtils.buildOutputScript(address: changeAddress)

            txBody.append(outputScriptChangeBytes.count.byte)
            txBody.append(contentsOf: outputScriptChangeBytes)
        }

        // 00000000
        txBody.append(contentsOf: [UInt8(0x00), UInt8(0x00), UInt8(0x00), UInt8(0x00)])

        return txBody
    }

    private func buildUnspents(signedOutputScripts: [Data]) -> [ScriptUnspentOutput] {
        assert(unspentOutputManager.allOutputs().count == signedOutputScripts.count)

        return zip(unspentOutputManager.allOutputs(), signedOutputScripts)
            .map { output, signedOutputScript in
                ScriptUnspentOutput(output: output.output, script: signedOutputScript)
            }
    }
}

// MARK: - UnspentTransaction

extension RadiantTransactionBuilder {
    struct UnspentTransaction {
        let decimalValue: Decimal
        let amount: Amount
        let fee: Fee
        let unspents: [ScriptUnspentOutput]

        var amountSatoshiDecimalValue: Decimal {
            let decimalValue = amount.value * decimalValue
            return decimalValue.rounded(roundingMode: .down)
        }

        var feeSatoshiDecimalValue: Decimal {
            let decimalValue = fee.amount.value * decimalValue
            return decimalValue.rounded(roundingMode: .up)
        }

        var changeSatoshiDecimalValue: Decimal {
            calculateChange(unspents: unspents, amountSatoshi: amountSatoshiDecimalValue, feeSatoshi: feeSatoshiDecimalValue)
        }

        private func calculateChange(
            unspents: [ScriptUnspentOutput],
            amountSatoshi: Decimal,
            feeSatoshi: Decimal
        ) -> Decimal {
            let fullAmountSatoshi = Decimal(unspents.reduce(0) { $0 + $1.amount })
            return fullAmountSatoshi - amountSatoshi - feeSatoshi
        }
    }
}
