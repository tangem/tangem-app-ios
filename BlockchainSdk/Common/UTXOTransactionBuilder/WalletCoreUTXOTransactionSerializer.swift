//
//  WalletCoreUTXOTransactionSerializer.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import WalletCore

struct WalletCoreUTXOTransactionSerializer {
    typealias Transaction = (transaction: BlockchainSdk.Transaction, preImage: PreImageTransaction)
    let coinType: CoinType
    let sequence: SequenceType

    init(coinType: CoinType, sequence: SequenceType) {
        self.coinType = coinType
        self.sequence = sequence
    }
}

// MARK: - UTXOTransactionSerializer

extension WalletCoreUTXOTransactionSerializer: UTXOTransactionSerializer {
    func preImageHashes(transaction: Transaction) throws -> [Data] {
        let input = try buildSigningInputInput(transaction: transaction)
        let txInputData = try input.serializedData()

        let preImageHashes = TransactionCompiler.preImageHashes(coinType: coinType, txInputData: txInputData)
        let preSigningOutput: BitcoinPreSigningOutput = try BitcoinPreSigningOutput(serializedData: preImageHashes)

        if preSigningOutput.error != .ok {
            BSDKLogger.error("BitcoinPreSigningOutput has a error", error: preSigningOutput.errorMessage)
            throw UTXOTransactionSerializerError.walletCoreError(preSigningOutput.errorMessage)
        }

        let hashes = preSigningOutput.hashPublicKeys.map { $0.dataHash }
        return hashes
    }

    func compile(transaction: Transaction, signatures: [SignatureInfo]) throws -> Data {
        let input = try buildSigningInputInput(transaction: transaction)
        let txInputData = try input.serializedData()

        let signaturesVector = DataVector()
        let publicKeysVector = DataVector()

        signatures.forEach { signature in
            signaturesVector.add(data: signature.signature)
            publicKeysVector.add(data: signature.publicKey)
        }

        let compileWithSignatures = TransactionCompiler.compileWithSignatures(
            coinType: coinType,
            txInputData: txInputData,
            signatures: signaturesVector,
            publicKeys: publicKeysVector
        )

        let output = try BitcoinSigningOutput(serializedData: compileWithSignatures)

        if output.error != .ok {
            BSDKLogger.error("BitcoinSigningOutput has a error", error: output.errorMessage)
            throw UTXOTransactionSerializerError.walletCoreError("\(output.error)")
        }

        if output.encoded.isEmpty {
            throw UTXOTransactionSerializerError.walletCoreError("Encoded is empty")
        }

        let encoded = output.encoded
        return encoded
    }
}

// MARK: - Private

private extension WalletCoreUTXOTransactionSerializer {
    func buildSigningInputInput(transaction: Transaction) throws -> BitcoinSigningInput {
        let utxo = transaction.preImage.inputs.map { input in
            BitcoinUnspentTransaction.with {
                $0.outPoint = .with {
                    $0.hash = Data(input.hash.reversed())
                    $0.index = UInt32(input.index)
                    $0.sequence = sequence.value
                }

                $0.amount = Int64(input.amount)
                $0.script = input.script.data
            }
        }

        let scripts: [String: Data] = transaction.preImage.inputs.reduce(into: [:]) { result, input in
            if case .redeemScript(let redeemScript) = input.script.spendable {
                result[redeemScript.sha256Ripemd160.hex()] = redeemScript
            }
        }

        guard let destination = transaction.preImage.outputs.first(where: { $0.isDestination }) else {
            throw UTXOTransactionSerializerError.noDestinationAmount
        }

        let change = transaction.preImage.outputs.first(where: { $0.isChange })

        let opReturnData = try opReturnData(from: transaction.transaction)

        var input = BitcoinSigningInput.with {
            $0.coinType = coinType.rawValue
            $0.hashType = WalletCore.TWBitcoinScriptHashTypeForCoin(.init(coinType.rawValue))
            $0.utxo = utxo
            $0.scripts = scripts
            $0.toAddress = transaction.transaction.destinationAddress
            $0.amount = Int64(destination.value)

            if change != nil {
                $0.changeAddress = transaction.transaction.changeAddress
            }

            if let opReturnData {
                $0.outputOpReturn = opReturnData
            }
        }

        input.plan = .with {
            $0.amount = Int64(destination.value)
            $0.availableAmount = utxo.sum(by: \.amount)
            $0.fee = Int64(transaction.preImage.fee)
            $0.utxos = utxo

            if let change {
                $0.change = Int64(change.value)
            }
        }

        if input.plan.error != .ok {
            BSDKLogger.error("BitcoinSigningInput has a error", error: "\(input.plan.error)")
            throw UTXOTransactionSerializerError.walletCoreError("\(input.plan.error)")
        }

        return input
    }

    func opReturnData(from transaction: BlockchainSdk.Transaction) throws -> Data? {
        guard let params = transaction.params as? BitcoinTransactionParams else {
            return nil
        }

        guard !params.memo.isEmpty else {
            return nil
        }

        // Standard OP_RETURN relay policy historically limits data to 80 bytes.
        if params.memo.count > 80 {
            throw UTXOTransactionSerializerError.walletCoreError("UTXO memo exceeds 80 bytes")
        }

        return params.memo
    }
}
