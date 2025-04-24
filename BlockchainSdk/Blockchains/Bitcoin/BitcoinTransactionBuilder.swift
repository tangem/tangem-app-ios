//
//  BitcoinTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import WalletCore

class BitcoinTransactionBuilder {
    private let network: UTXONetworkParams
    private let unspentOutputManager: UnspentOutputManager
    private let coinType: CoinType = .bitcoin

    init(network: UTXONetworkParams, unspentOutputManager: UnspentOutputManager) {
        self.network = network
        self.unspentOutputManager = unspentOutputManager
    }

    func fee(amount: Amount, address: String, feeRate: Int) async throws -> Int {
        let satoshi = amount.asSmallest().value.intValue()
        let preImage = try await unspentOutputManager.preImage(amount: satoshi, feeRate: feeRate, destination: address)
        return preImage.fee
    }

    func buildForSign(transaction: Transaction) async throws -> [Data] {
        let input = try await buildSigningInputInput(transaction: transaction)
        let txInputData = try input.serializedData()

        let preImageHashes = TransactionCompiler.preImageHashes(coinType: coinType, txInputData: txInputData)
        let preSigningOutput: BitcoinPreSigningOutput = try BitcoinPreSigningOutput(serializedData: preImageHashes)

        if preSigningOutput.error != .ok {
            BSDKLogger.error("BitcoinPreSigningOutput has a error", error: preSigningOutput.errorMessage)
            throw Error.walletCoreError(preSigningOutput.errorMessage)
        }

        let hashes = preSigningOutput.hashPublicKeys.map { $0.dataHash }
        return hashes
    }

    func buildForSend(transaction: Transaction, signatures: [SignatureInfo]) async throws -> Data {
        let input = try await buildSigningInputInput(transaction: transaction)
        let txInputData = try input.serializedData()

        let signaturesVector = DataVector()
        let publicKeysVector = DataVector()

        try signatures.forEach { signature in
            try signaturesVector.add(data: signature.der())
            try publicKeysVector.add(data: Secp256k1Key(with: signature.publicKey).compress())
        }

        let compileWithSignatures = TransactionCompiler.compileWithSignatures(
            coinType: .bitcoin,
            txInputData: txInputData,
            signatures: signaturesVector,
            publicKeys: publicKeysVector
        )

        let output = try BitcoinSigningOutput(serializedData: compileWithSignatures)

        if output.error != .ok {
            BSDKLogger.error("BitcoinSigningOutput has a error", error: output.errorMessage)
            throw Error.walletCoreError("\(output.error)")
        }

        if output.encoded.isEmpty {
            throw Error.walletCoreError("Encoded is empty")
        }

        let encoded = output.encoded
        return encoded
    }
}

// MARK: - Private

private extension BitcoinTransactionBuilder {
    func buildSigningInputInput(transaction: Transaction) async throws -> BitcoinSigningInput {
        guard let parameters = transaction.fee.parameters as? BitcoinFeeParameters else {
            throw Error.noBitcoinFeeParameters
        }

        let preImage = try await unspentOutputManager.preImage(transaction: transaction)

        guard let destination = preImage.outputs.first(where: { $0.isDestination }) else {
            throw Error.noDestinationAmount
        }

        let change = preImage.outputs.first(where: { $0.isChange })

        let utxo = preImage.inputs.map { input in
            BitcoinUnspentTransaction.with {
                $0.outPoint = .with {
                    $0.hash = Data(input.hash.reversed())
                    $0.index = UInt32(input.index)
                    $0.sequence = .max
                }

                $0.amount = Int64(input.amount)
                $0.script = input.script.data
            }
        }

        let scripts: [String: Data] = preImage.inputs.reduce(into: [:]) { result, input in
            input.script.redeemScript.map { redeemScript in
                result[input.script.keyHash.hexString.lowercased()] = redeemScript
            }
        }

        var input = BitcoinSigningInput.with {
            $0.coinType = network.coinType
            $0.hashType = network.signHashType.value
            $0.utxo = utxo
            $0.scripts = scripts

            $0.toAddress = transaction.destinationAddress
            $0.amount = Int64(destination.value)

            $0.changeAddress = transaction.changeAddress
            $0.useMaxAmount = change == nil

            $0.byteFee = Int64(parameters.rate)
        }

        input.plan = AnySigner.plan(input: input, coin: coinType)
        if input.plan.error != .ok {
            BSDKLogger.error("BitcoinSigningInput has a error", error: "\(input.plan.error)")
            throw Error.walletCoreError("\(input.plan.error)")
        }

        return input
    }
}

extension BitcoinTransactionBuilder {
    enum Error: LocalizedError {
        case unsupportedBlockchain(String)
        case unsupportedAddresses
        case wrongType
        case noBitcoinFeeParameters
        case noDestinationAmount
        case walletCoreError(String)
    }
}
