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

    private let lockingScriptBuilder: LockingScriptBuilder = .radiant()
    private let scriptUtils = RadiantScriptUtils()

    // MARK: - Init

    init(walletPublicKey: Data, unspentOutputManager: UnspentOutputManager, decimalValue: Decimal) throws {
        self.walletPublicKey = try Secp256k1Key(with: walletPublicKey).compress()
        self.unspentOutputManager = unspentOutputManager
        self.decimalValue = decimalValue
    }

    // MARK: - Implementation

    func buildForSign(transaction: Transaction) async throws -> [Data] {
        let sourceLockingScript = try lockingScriptBuilder.lockingScript(for: transaction.sourceAddress)
        let (unspents, outputs) = try await buildPreImageData(transaction: transaction)

        let hashes = unspents.enumerated().map { index, _ in
            let preImageHash = buildPreImageHashes(
                sourceScript: sourceLockingScript,
                unspents: unspents,
                outputs: outputs,
                index: index
            )

            return preImageHash.getDoubleSHA256()
        }

        return hashes
    }

    func buildForSend(transaction: Transaction, signatures: [Data]) async throws -> Data {
        let signedOutputScripts = try scriptUtils.buildSignedScripts(signatures: signatures, publicKey: walletPublicKey)
        let (unspents, outputs) = try await buildPreImageData(transaction: transaction)

        let inputs = zip(unspents, signedOutputScripts).map { output, signedOutputScript in
            TransactionInput(previousOutputHash: output.hash, previousOutputIndex: output.index, amount: output.amount, signedScript: signedOutputScript)
        }

        let rawTransaction = buildRawTransaction(inputs: inputs, outputs: outputs)
        return rawTransaction
    }

    func estimateFee(amount: Amount, destination: String, feeRate: Int) async throws -> Int {
        let amount = amount.asSmallest().value.intValue()
        let preImage = try await unspentOutputManager.preImage(amount: amount, feeRate: feeRate, destination: destination)
        return preImage.fee
    }

    private func buildPreImageData(transaction: Transaction) async throws -> (unspents: [UnspentOutput], outputs: [TransactionOutput]) {
        let preImage = try await unspentOutputManager.preImage(transaction: transaction)

        let unspents = preImage.inputs.map {
            UnspentOutput(hash: $0.hash, index: $0.index, amount: $0.amount, script: $0.script.data)
        }

        let outputs = preImage.outputs.map {
            TransactionOutput(amount: UInt64($0.value), lockingScript: $0.script)
        }

        return (unspents: unspents, outputs: outputs)
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
        sourceScript: UTXOLockingScript,
        unspents: [UnspentOutput],
        outputs: [TransactionOutput],
        index: Int
    ) -> Data {
        var txToSign = Data()

        // version
        txToSign.append(contentsOf: [UInt8(0x01), UInt8(0x00), UInt8(0x00), UInt8(0x00)])

        // hashPrevouts
        scriptUtils.writePrevoutHash(unspents, into: &txToSign)

        // hashSequence
        scriptUtils.writeSequenceHash(unspents, into: &txToSign)

        // outpoint
        let currentOutput = unspents[index]
        txToSign.append(contentsOf: currentOutput.hash.reversed())
        txToSign.append(contentsOf: currentOutput.index.bytes4LE)

        txToSign.append(sourceScript.data.count.byte)
        txToSign.append(contentsOf: sourceScript.data)

        // value of the output spent by this input (8-byte little endian)
        txToSign.append(contentsOf: currentOutput.amount.bytes8LE)

        // nSequence of the input (4-byte little endian), ffffffff only
        txToSign.append(contentsOf: [UInt8(0xff), UInt8(0xff), UInt8(0xff), UInt8(0xff)])

        // hashOutputHashes (32-byte hash)
        scriptUtils.writeHashOutputHashes(outputs: outputs, into: &txToSign)

        // hashOutputs (32-byte hash)
        scriptUtils.writeHashOutput(outputs: outputs, into: &txToSign)

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
        inputs: [TransactionInput],
        outputs: [TransactionOutput]
    ) -> Data {
        var txBody = Data()

        // version
        txBody.append(contentsOf: [UInt8(0x01), UInt8(0x00), UInt8(0x00), UInt8(0x00)])

        // 01
        txBody.append(inputs.count.byte)

        // hex str hash prev btc
        inputs.forEach { input in
            let hashKey: [UInt8] = input.previousOutputHash.reversed()
            txBody.append(contentsOf: hashKey)
            txBody.append(contentsOf: input.previousOutputIndex.bytes4LE)
            txBody.append(input.signedScript.count.byte)
            txBody.append(contentsOf: input.signedScript)

            // ffffffff
            txBody.append(contentsOf: [UInt8(0xff), UInt8(0xff), UInt8(0xff), UInt8(0xff)]) // sequence
        }

        // 02
        txBody.append(outputs.count.byte)

        outputs.forEach { output in
            // 8 bytes
            txBody.append(output.amount.bytes8LE)
            txBody.append(output.lockingScript.data.count.byte)
            txBody.append(output.lockingScript.data)
        }

        // 00000000
        txBody.append(contentsOf: [UInt8(0x00), UInt8(0x00), UInt8(0x00), UInt8(0x00)])
        return txBody
    }
}

// MARK: - UnspentTransaction

extension RadiantTransactionBuilder {
    struct UnspentOutput {
        let hash: Data
        let index: Int
        let amount: UInt64
        let script: Data
    }

    struct TransactionInput {
        let previousOutputHash: Data
        let previousOutputIndex: Int
        let amount: UInt64
        let signedScript: Data
    }

    struct TransactionOutput {
        let amount: UInt64
        let lockingScript: UTXOLockingScript
    }
}
