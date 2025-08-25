//
//  KaspaTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore
import TangemSdk
import TangemFoundation

class KaspaTransactionBuilder {
    /// 0.2 KAS
    static let dustValue: Int = 20_000_000

    private let blockchain: Blockchain
    private let walletPublicKey: Wallet.PublicKey
    private let unspentOutputManager: UnspentOutputManager
    private let addressService: KaspaAddressService

    init(walletPublicKey: Wallet.PublicKey, unspentOutputManager: UnspentOutputManager, isTestnet: Bool) {
        self.walletPublicKey = walletPublicKey
        self.unspentOutputManager = unspentOutputManager

        blockchain = .kaspa(testnet: isTestnet)
        addressService = KaspaAddressService(isTestnet: isTestnet)
    }

    func availableAmount() -> Amount {
        let availableAmountInSatoshi = unspentOutputManager.availableOutputs().sum(by: \.amount)
        return Amount(with: blockchain, value: Decimal(availableAmountInSatoshi) / blockchain.decimalValue)
    }
}

// MARK: - Coin

extension KaspaTransactionBuilder {
    func buildForSign(transaction: Transaction) async throws -> (transaction: KaspaTransaction, hashes: [Data]) {
        try await buildForSign(amount: transaction.amount, feeType: .exactly(transaction.fee), destination: transaction.destinationAddress)
    }

    func buildForMassCalculation(amount: Amount, feeRate: Int, sourceAddress: String, destination: String) async throws -> KaspaDTO.Send.Request.Transaction {
        let amountValue = min(amount.value, availableAmount().value)
        let amount = Amount(with: blockchain, value: amountValue)

        let (builtTransaction, _) = try await buildForSign(
            amount: amount,
            feeType: .calculation(feeRate: feeRate),
            destination: destination
        )

        let dummySignature = Data(repeating: 1, count: 65)

        return mapToTransaction(
            transaction: builtTransaction,
            signatures: Array(repeating: dummySignature, count: builtTransaction.inputs.count)
        )
    }

    private func buildForSign(amount: Amount, feeType: FeeType, destination: String) async throws -> (KaspaTransaction, [Data]) {
        guard case .coin = amount.type else {
            throw BlockchainSdkError.notImplemented
        }

        try validateAvailableAmount(amount: amount)
        let amount = amount.asSmallest().value.intValue()

        let preImage: PreImageTransaction = try await {
            switch feeType {
            case .exactly(let fee):
                let fee = fee.amount.asSmallest().value.intValue()
                return try await unspentOutputManager.preImage(amount: amount, fee: fee, destination: destination)
            case .calculation(let feeRate):
                return try await unspentOutputManager.preImage(amount: amount, feeRate: feeRate, destination: destination)
            }
        }()

        let inputs: [KaspaTransaction.Input] = preImage.inputs.map {
            .init(transactionHash: $0.hash, outputIndex: $0.index, amount: $0.amount, script: $0.script.data)
        }

        let outputs: [KaspaTransaction.Output] = preImage.outputs.map { output in
            switch output {
            case .destination(let script, let value):
                return .init(amount: UInt64(value), scriptPublicKey: .init(script: script.data))
            case .change(let script, let value):
                return .init(amount: UInt64(value), scriptPublicKey: .init(script: script.data))
            }
        }

        let kaspaTransaction = KaspaTransaction(inputs: inputs, outputs: outputs)
        let hashes = kaspaTransaction.hashesForSignatureWitness()
        return (kaspaTransaction, hashes)
    }
}

// MARK: - Tokens

extension KaspaTransactionBuilder {
    func buildForSignKRC20(transaction: Transaction) async throws -> (txgroup: KaspaKRC20.TransactionGroup, meta: KaspaKRC20.TransactionMeta) {
        // Commit
        let resultCommit = try await buildCommitTransactionKRC20(
            amount: transaction.amount,
            feeType: .exactly(transaction.fee),
            sourceAddress: transaction.sourceAddress,
            destination: transaction.destinationAddress
        )

        // Reveal
        let resultReveal = try buildRevealTransactionKRC20(
            sourceAddress: transaction.sourceAddress,
            params: resultCommit.params,
            fee: transaction.fee
        )

        return (
            KaspaKRC20.TransactionGroup(
                kaspaCommitTransaction: resultCommit.transaction,
                kaspaRevealTransaction: resultReveal.transaction,
                hashesCommit: resultCommit.hashes,
                hashesReveal: resultReveal.hashes
            ),
            KaspaKRC20.TransactionMeta(
                redeemScriptCommit: resultCommit.redeemScript,
                incompleteTransactionParams: resultCommit.params
            )
        )
    }

    /// Just a proxy for external consumers.
    func buildForSignRevealTransactionKRC20(
        sourceAddress: String,
        params: KaspaKRC20.IncompleteTokenTransactionParams,
        fee: Fee
    ) throws -> KaspaKRC20.RevealTransaction {
        return try buildRevealTransactionKRC20(sourceAddress: sourceAddress, params: params, fee: fee)
    }

    func buildForMassCalculationKRC20(amount: Amount, feeRate: Int, sourceAddress: String, destination: String) async throws -> KaspaDTO.Send.Request.Transaction {
        let dummySignature = Data(repeating: 1, count: 65)
        let commitTx = try await buildCommitTransactionKRC20(
            amount: amount,
            feeType: .calculation(feeRate: feeRate),
            sourceAddress: sourceAddress,
            destination: destination
        )

        return mapToTransaction(
            transaction: commitTx.transaction,
            signatures: Array(repeating: dummySignature, count: commitTx.transaction.inputs.count)
        )
    }

    private func buildCommitTransactionKRC20(amount: Amount, feeType: FeeType, sourceAddress: String, destination: String) async throws -> KaspaKRC20.CommitTransaction {
        guard case .token(let token) = amount.type else {
            throw BlockchainSdkError.failedToBuildTx
        }

        func preImage() async throws -> (preImage: PreImageTransaction, targetOutputAmount: Int) {
            let dust = KaspaTransactionBuilder.dustValue

            switch feeType {
            case .exactly(let fee):
                try validateAvailableAmount(amount: fee.amount)

                guard let feeParams = fee.parameters as? KaspaKRC20.TokenTransactionFeeParams else {
                    throw BlockchainSdkError.failedToBuildTx
                }

                let targetOutputAmount = dust + feeParams.revealFee.asSmallest().value.intValue()
                let fee = feeParams.commitFee.asSmallest().value.intValue()
                let preImage = try await unspentOutputManager.preImage(amount: targetOutputAmount, fee: fee, destination: destination)
                return (preImage: preImage, targetOutputAmount: targetOutputAmount)
            case .calculation(let feeRate):
                let preImage = try await unspentOutputManager.preImage(amount: dust, feeRate: feeRate, destination: destination)
                return (preImage: preImage, targetOutputAmount: dust)
            }
        }

        // The envelope will be used to create the RedeemScript and saved for use when building the Reveal transaction
        let envelope = KaspaKRC20.Envelope(
            amount: amount.asSmallest().value,
            recipient: destination,
            ticker: token.contractAddress
        )

        // Some older cards use uncompressed secp256k1 public keys, while Kaspa only works with compressed ones
        let publicKey = try Secp256k1Key(with: walletPublicKey.blockchainKey).compress()

        // Create a RedeemScript for the 1st output of the Commit transaction, this is part of the KRC20 protocol
        let redeemScript = KaspaKRC20.RedeemScript(publicKey: publicKey, envelope: envelope)

        // Build preImage transaction
        let (preImage, targetOutputAmount) = try await preImage()

        let inputs: [KaspaTransaction.Input] = preImage.inputs.map {
            .init(transactionHash: $0.hash, outputIndex: $0.index, amount: $0.amount, script: $0.script.data)
        }

        let outputs: [KaspaTransaction.Output] = preImage.outputs.map { output in
            switch output {
            case .destination(_, let value):
                return .init(amount: UInt64(value), scriptPublicKey: .init(script: redeemScript.redeemScriptHash))
            case .change(let script, let value):
                return .init(amount: UInt64(value), scriptPublicKey: .init(script: script.data))
            }
        }

        // Build Commit transaction
        let commitTransaction = KaspaTransaction(inputs: inputs, outputs: outputs)

        // Prepare hashes for signing
        let commitHashes = commitTransaction.hashesForSignatureWitness()

        // Get transactionId of the Commit transaction for use when creating utxo for Reveal transaction
        guard let txid = commitTransaction.transactionId else {
            throw BlockchainSdkError.failedToBuildTx
        }

        // Return CommitTransaction structure, that includes IncompleteTokenTransactionParams to persist if the Reveal transaction fails
        return KaspaKRC20.CommitTransaction(
            transaction: commitTransaction,
            hashes: commitHashes,
            redeemScript: redeemScript,
            sourceAddress: sourceAddress,
            params: .init(
                transactionId: txid.hex(),
                amount: amount.value,
                targetOutputAmount: UInt64(targetOutputAmount),
                envelope: envelope
            )
        )
    }

    private func buildRevealTransactionKRC20(
        sourceAddress: String,
        params: KaspaKRC20.IncompleteTokenTransactionParams,
        fee: Fee
    ) throws -> KaspaKRC20.RevealTransaction {
        // Some older cards use uncompressed secp256k1 public keys, while Kaspa only works with compressed ones
        let publicKey = try Secp256k1Key(with: walletPublicKey.blockchainKey).compress()
        let redeemScript = KaspaKRC20.RedeemScript(publicKey: publicKey, envelope: params.envelope)
        let sourceAddressScript = try addressService.scriptPublicKey(address: sourceAddress)

        guard let feeParams = fee.parameters as? KaspaKRC20.TokenTransactionFeeParams else {
            throw BlockchainSdkError.failedToBuildTx
        }

        let inputs: [KaspaTransaction.Input] = [
            .init(
                transactionHash: Data(hexString: params.transactionId),
                outputIndex: 0,
                amount: params.targetOutputAmount,
                script: redeemScript.redeemScriptHash
            ),
        ]

        let fullAmount = inputs.sum(by: \.amount)
        let fee = feeParams.revealFee.asSmallest().value.rounded().uint64Value
        let change = fullAmount - fee

        let outputs: [KaspaTransaction.Output] = [
            .init(amount: change, scriptPublicKey: .init(script: sourceAddressScript)),
        ]

        let transaction = KaspaTransaction(inputs: inputs, outputs: outputs)
        let hashes = transaction.hashesForSignatureWitness()

        return KaspaKRC20.RevealTransaction(transaction: transaction, hashes: hashes, redeemScript: redeemScript)
    }
}

// MARK: - Mapping

extension KaspaTransactionBuilder {
    /// Build the transaction DTO model which will be send to API
    func mapToTransaction(transaction: KaspaTransaction, signatures: [Data]) -> KaspaDTO.Send.Request.Transaction {
        let inputs: [KaspaDTO.Send.Request.Transaction.Input] = transaction.inputs.enumerated().map { index, input in
            let sigHashAll: UInt8 = 1
            let script = signatures[index] + sigHashAll.data
            let signatureScript = OpCode.push(script).hex()

            let outpoint = KaspaDTO.Send.Request.Transaction.Input.PreviousOutpoint(
                transactionId: input.transactionHash.hex(),
                index: input.outputIndex
            )

            return .init(previousOutpoint: outpoint, signatureScript: signatureScript)
        }

        let outputs: [KaspaDTO.Send.Request.Transaction.Output] = transaction.outputs.map {
            .init(
                amount: $0.amount,
                scriptPublicKey: .init(
                    scriptPublicKey: $0.scriptPublicKey.script.hex(),
                    version: $0.scriptPublicKey.version
                )
            )
        }

        return KaspaDTO.Send.Request.Transaction(inputs: inputs, outputs: outputs)
    }

    func mapToRevealTransaction(transaction builtTransaction: KaspaTransaction, commitRedeemScript: Data, signatures: [Data]) -> KaspaDTO.Send.Request.Transaction {
        let inputs: [KaspaDTO.Send.Request.Transaction.Input] = builtTransaction.inputs.enumerated().map { index, input in
            let sigHashAll: UInt8 = 1
            let script = signatures[index] + sigHashAll.data

            let outpoint = KaspaDTO.Send.Request.Transaction.Input.PreviousOutpoint(
                transactionId: input.transactionHash.hex(),
                index: input.outputIndex
            )

            switch index {
            case 0:
                let signatureScript = (OpCode.push(script) + OpCode.push(commitRedeemScript)).hex()
                return .init(previousOutpoint: outpoint, signatureScript: signatureScript)

            default:
                let signatureScript = OpCode.push(script).hex()
                return .init(previousOutpoint: outpoint, signatureScript: signatureScript)
            }
        }

        let outputs: [KaspaDTO.Send.Request.Transaction.Output] = builtTransaction.outputs.map {
            .init(
                amount: $0.amount,
                scriptPublicKey: .init(
                    scriptPublicKey: $0.scriptPublicKey.script.hex(),
                    version: $0.scriptPublicKey.version
                )
            )
        }

        return .init(inputs: inputs, outputs: outputs)
    }
}

// MARK: - Validation

private extension KaspaTransactionBuilder {
    func validateAvailableAmount(amount: Amount) throws {
        let availableInputValue = availableAmount()

        guard amount.type == availableInputValue.type,
              amount <= availableInputValue else {
            throw BlockchainSdkError.failedToBuildTx
        }

        // All good
    }
}

extension KaspaTransactionBuilder {
    enum FeeType {
        case exactly(Fee)
        case calculation(feeRate: Int)
    }
}
