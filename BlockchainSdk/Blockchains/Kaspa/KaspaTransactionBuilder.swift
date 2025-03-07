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
    let maxInputCount = 84

    private let blockchain: Blockchain
    private let walletPublicKey: Wallet.PublicKey
    private let unspentOutputManager: UnspentOutputManager
    private let addressService: KaspaAddressService

    /// All outputs
    var unspentOutputs: [KaspaTransaction.Input] {
        let sortedOutputs = unspentOutputManager.allOutputs().sorted { $0.amount > $1.amount }
        let maxOutputs = sortedOutputs.prefix(maxInputCount)

        return maxOutputs.map {
            KaspaTransaction.Input(hash: $0.hash, index: $0.index, amount: $0.amount, script: $0.script)
        }
    }

    init(blockchain: Blockchain, walletPublicKey: Wallet.PublicKey, unspentOutputManager: UnspentOutputManager) {
        self.blockchain = blockchain
        self.walletPublicKey = walletPublicKey
        self.unspentOutputManager = unspentOutputManager

        addressService = KaspaAddressService(isTestnet: blockchain.isTestnet)
    }

    func availableAmount() -> Amount {
        let availableAmountInSatoshi = unspentOutputs.sum(by: \.amount)
        return Amount(with: blockchain, value: Decimal(availableAmountInSatoshi) / blockchain.decimalValue)
    }

    func buildForSign(_ transaction: Transaction) throws -> (KaspaTransaction, [Data]) {
        switch transaction.amount.type {
        case .token(let token):
            let commitTx = try buildCommitTransactionKRC20(transaction: transaction, token: token)
            return (commitTx.transaction, commitTx.hashes)
        case .coin:
            return try buildCommitTransactionCoin(transaction)
        default:
            throw BlockchainSdkError.notImplemented
        }
    }

    /// Build the transaction DTO model which will be send to API
    func buildForSend(transaction: KaspaTransaction, signatures: [Data]) -> KaspaDTO.Send.Request.Transaction {
        let inputs = transaction.inputs.enumerated().map { index, input in
            let sigHashAll: UInt8 = 1
            let script = signatures[index] + sigHashAll.data
            let size = UInt8(script.count)

            let signatureScript = (size.data + script).hexadecimal
            let outpoint = KaspaDTO.Send.Request.Transaction.Input.PreviousOutpoint(transactionId: input.hash.hexString, index: input.index)
            return KaspaDTO.Send.Request.Transaction.Input(previousOutpoint: outpoint, signatureScript: signatureScript)
        }

        let outputs: [KaspaDTO.Send.Request.Transaction.Output] = transaction.outputs.map {
            .init(
                amount: $0.amount,
                scriptPublicKey: .init(
                    scriptPublicKey: $0.scriptPublicKey.script.hexString.lowercased(),
                    version: $0.scriptPublicKey.version
                )
            )
        }

        return KaspaDTO.Send.Request.Transaction(inputs: inputs, outputs: outputs)
    }

    func buildForSendReveal(transaction: KaspaTransaction, commitRedeemScript: KaspaKRC20.RedeemScript, signatures: [Data]) -> KaspaDTO.Send.Request.Transaction {
        let inputs = transaction.inputs.enumerated().map { index, input in
            let sigHashAll: UInt8 = 1
            let script = signatures[index] + sigHashAll.data
            let size = UInt8(script.count)

            let outpoint = KaspaDTO.Send.Request.Transaction.Input.PreviousOutpoint(transactionId: input.hash.hexString, index: input.index)

            switch index {
            case 0:
                let commitRedeemScriptData = commitRedeemScript.data
                let commitRedeemScriptDataCount = commitRedeemScriptData.count
                var commitRedeemScriptOpCodeData: Data

                switch commitRedeemScriptDataCount {
                case 0 ... 255:
                    commitRedeemScriptOpCodeData = OpCode.OP_PUSHDATA1.value.data + UInt8(commitRedeemScriptDataCount & 0xff).data
                case 255 ... 65535:
                    commitRedeemScriptOpCodeData = OpCode.OP_PUSHDATA2.value.data + UInt16(commitRedeemScriptDataCount & 0xffff).data
                default:
                    commitRedeemScriptOpCodeData = OpCode.OP_PUSHDATA4.value.data + UInt32(commitRedeemScriptDataCount & 0xffffffff).data
                }

                let signatureScript = (size.data + script + commitRedeemScriptOpCodeData + commitRedeemScript.data).hexadecimal
                return KaspaDTO.Send.Request.Transaction.Input(previousOutpoint: outpoint, signatureScript: signatureScript)

            default:
                let signatureScript = (size.data + script).hexadecimal
                return KaspaDTO.Send.Request.Transaction.Input(previousOutpoint: outpoint, signatureScript: signatureScript)
            }
        }

        let outputs: [KaspaDTO.Send.Request.Transaction.Output] = transaction.outputs.map {
            .init(
                amount: $0.amount,
                scriptPublicKey: .init(
                    scriptPublicKey: $0.scriptPublicKey.script.hexString.lowercased(),
                    version: $0.scriptPublicKey.version
                )
            )
        }

        return KaspaDTO.Send.Request.Transaction(inputs: inputs, outputs: outputs)
    }

    func buildForMassCalculation(transaction: Transaction) throws -> KaspaDTO.Send.Request.Transaction {
        let amountValue = min(transaction.amount.value, availableAmount().value)
        let amount = Amount(with: blockchain, value: amountValue)

        let transaction = transaction.withAmount(amount)

        let builtTransaction = try buildForSign(transaction).0
        let dummySignature = Data(repeating: 1, count: 65)
        return buildForSend(
            transaction: builtTransaction,
            signatures: Array(
                repeating: dummySignature,
                count: builtTransaction.inputs.count
            )
        )
    }

    private func scriptPublicKey(address: String) throws -> Data {
        try addressService.scriptPublicKey(address: address)
    }
}

// MARK: - Coin

extension KaspaTransactionBuilder {
    func buildCommitTransactionCoin(_ transaction: Transaction) throws -> (KaspaTransaction, [Data]) {
        let availableInputValue = availableAmount()

        guard transaction.amount.type == availableInputValue.type,
              transaction.amount <= availableInputValue else {
            throw WalletError.failedToBuildTx
        }

        let destinationAddressScript = try scriptPublicKey(address: transaction.destinationAddress)

        var outputs: [KaspaTransaction.Output] = [
            .init(
                amount: (transaction.amount.value * blockchain.decimalValue).uint64Value,
                scriptPublicKey: .init(script: destinationAddressScript)
            ),
        ]

        let amount = transaction.amount.value
        let fee = transaction.fee.amount.value
        let fullAmount = unspentOutputs.sum(by: \.amount)

        if let change = try change(amount: amount, fee: fee, fullAmount: fullAmount) {
            let sourceAddressScript = try scriptPublicKey(address: transaction.sourceAddress)
            outputs.append(
                .init(
                    amount: change,
                    scriptPublicKey: .init(script: sourceAddressScript)
                )
            )
        }

        let kaspaTransaction = KaspaTransaction(inputs: unspentOutputs, outputs: outputs)
        let hashes = unspentOutputs.enumerated().map { index, unspentOutput in
            kaspaTransaction.hashForSignatureWitness(
                inputIndex: index,
                connectedScript: unspentOutput.script,
                prevValue: unspentOutput.amount
            )
        }

        return (kaspaTransaction, hashes)
    }
}

// MARK: - Tokens

extension KaspaTransactionBuilder {
    func buildForMassCalculationKRC20(transaction: Transaction, token: Token) throws -> KaspaDTO.Send.Request.Transaction {
        let dummySignature = Data(repeating: 1, count: 65)
        let commitTx = try buildCommitTransactionKRC20(transaction: transaction, token: token, includeFee: false)

        return buildForSend(
            transaction: commitTx.transaction,
            signatures: Array(
                repeating: dummySignature,
                count: commitTx.transaction.inputs.count
            )
        )
    }

    func buildForSignKRC20(transaction: Transaction, token: Token) throws -> (KaspaKRC20.TransactionGroup, KaspaKRC20.TransactionMeta) {
        // Commit
        let resultCommit = try buildCommitTransactionKRC20(transaction: transaction, token: token)

        // Reveal
        guard let feeParams = transaction.fee.parameters as? KaspaKRC20.TokenTransactionFeeParams else {
            throw WalletError.failedToBuildTx
        }

        let resultReveal = try buildRevealTransactionKRC20(
            sourceAddress: transaction.sourceAddress,
            params: resultCommit.params,
            fee: .init(feeParams.revealFee)
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

    private func buildCommitTransactionKRC20(transaction: Transaction, token: Token, includeFee: Bool = true) throws -> KaspaKRC20.CommitTransaction {
        let availableInputValue = availableAmount()

        // We check there are enough funds to cover the commission,
        // the token transfer amount is not included in the verification
        guard transaction.fee.amount.type == availableInputValue.type,
              transaction.fee.amount <= availableInputValue else {
            throw WalletError.failedToBuildTx
        }

        // Get the decimals value for the token to create an envelope
        guard let tokenDecimalValue = transaction.amount.type.token?.decimalValue else {
            throw WalletError.failedToBuildTx
        }

        let commitFeeAmount: Amount
        let revealFeeAmount: Amount?

        // The includeFee flag determines whether we already know the commission value
        // or the method is called for preliminary calculation mass
        if includeFee {
            // if the commission is included,
            // but the additional fee parameter KaspaKRC20.RevealTransactionFeeParameter is missing - it is impossible to build a transaction
            guard let feeParams = transaction.fee.parameters as? KaspaKRC20.TokenTransactionFeeParams else {
                throw WalletError.failedToBuildTx
            }

            commitFeeAmount = feeParams.commitFee
            revealFeeAmount = feeParams.revealFee
        } else {
            commitFeeAmount = transaction.fee.amount
            revealFeeAmount = nil
        }

        // if we don't know the commission, commission for reveal transaction will be set to zero
        let feeEstimationRevealTransactionValue = ((revealFeeAmount?.value ?? 0) * blockchain.decimalValue).rounded()
        let dust = (Decimal(0.2) * blockchain.decimalValue).rounded()

        let tokenAmount = transaction.amount.value * tokenDecimalValue

        // The envelope will be used to create the RedeemScript and saved for use when building the Reveal transaction
        let envelope = KaspaKRC20.Envelope(
            amount: tokenAmount,
            recipient: transaction.destinationAddress,
            ticker: token.contractAddress
        )

        // Some older cards use uncompressed secp256k1 public keys, while Kaspa only works with compressed ones
        let publicKey = try Secp256k1Key(with: walletPublicKey.blockchainKey).compress()

        // Create a RedeemScript for the 1st output of the Commit transaction, this is part of the KRC20 protocol
        let redeemScript = KaspaKRC20.RedeemScript(publicKey: publicKey, envelope: envelope)
        let targetOutputAmount = dust.uint64Value + feeEstimationRevealTransactionValue.uint64Value

        // 1st output of the Commit transaction
        var outputs: [KaspaTransaction.Output] = [
            .init(
                amount: targetOutputAmount,
                scriptPublicKey: .init(script: redeemScript.redeemScriptHash)
            ),
        ]

        // 2nd output of the Commit transaction, create it if we still have funds that need to be returned to the source address.
        // Change = all available funds - (dust + estimated reveal transaction fee + estimated commit transaction fee)
        let amount = dust + feeEstimationRevealTransactionValue
        let fee = (commitFeeAmount.value * blockchain.decimalValue).rounded()
        let fullAmount = unspentOutputs.sum(by: \.amount)
        if let change = try change(amount: amount, fee: fee, fullAmount: fullAmount) {
            let sourceAddressScript = try scriptPublicKey(address: transaction.sourceAddress)
            outputs.append(
                .init(
                    amount: change,
                    scriptPublicKey: .init(script: sourceAddressScript)
                )
            )
        }

        // Build Commit transaction
        let commitTransaction = KaspaTransaction(inputs: unspentOutputs, outputs: outputs)

        // Prepare hashes for signing
        let commitHashes = unspentOutputs.enumerated().map { index, unspentOutput in
            commitTransaction.hashForSignatureWitness(
                inputIndex: index,
                connectedScript: unspentOutput.script,
                prevValue: unspentOutput.amount
            )
        }

        // Get transactionId of the Commit transaction for use when creating utxo for Reveal transaction
        guard let txid = commitTransaction.transactionId else {
            throw WalletError.failedToBuildTx
        }

        // Return CommitTransaction structure, that includes IncompleteTokenTransactionParams to persist if the Reveal transaction fails
        return KaspaKRC20.CommitTransaction(
            transaction: commitTransaction,
            hashes: commitHashes,
            redeemScript: redeemScript,
            sourceAddress: transaction.sourceAddress,
            params: .init(
                transactionId: txid.hexadecimal,
                amount: transaction.amount.value,
                targetOutputAmount: targetOutputAmount,
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
        let sourceAddressScript = try scriptPublicKey(address: sourceAddress)

        let inputs: [KaspaTransaction.Input] = [
            KaspaTransaction.Input(
                hash: Data(hexString: params.transactionId),
                index: 0,
                amount: params.targetOutputAmount,
                script: redeemScript.redeemScriptHash
            ),
        ]

        let fee = (fee.amount.value * blockchain.decimalValue).rounded()
        let fullAmount = inputs.sum(by: \.amount)
        let change = try change(amount: 0, fee: fee, fullAmount: fullAmount)!

        let outputs = [
            KaspaTransaction.Output(amount: change, scriptPublicKey: .init(script: sourceAddressScript)),
        ]

        let transaction = KaspaTransaction(inputs: inputs, outputs: outputs)
        let hashes = inputs.enumerated().map { index, unspentOutput in
            transaction.hashForSignatureWitness(
                inputIndex: index,
                connectedScript: unspentOutput.script,
                prevValue: unspentOutput.amount
            )
        }

        return KaspaKRC20.RevealTransaction(transaction: transaction, hashes: hashes, redeemScript: redeemScript)
    }

    private func change(amount: Decimal, fee: Decimal, fullAmount: UInt64) throws -> UInt64? {
        let transactionAmount = amount.uint64Value
        let feeAmount = fee.uint64Value

        let amountCharged = transactionAmount + feeAmount

        if fullAmount > amountCharged {
            return fullAmount - amountCharged
        }

        if fullAmount == amountCharged {
            // No change. Send full
            return nil
        }

        throw WalletError.failedToBuildTx
    }
}
