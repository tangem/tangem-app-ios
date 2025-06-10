//
//  TONTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit
import WalletCore
import TonSwift
import BigInt

/// Transaction builder for TON wallet
final class TONTransactionBuilder {
    // MARK: - Properties

    /// Sequence number of transactions
    var sequenceNumber: Int = 0

    // MARK: - Private Properties

    private let wallet: Wallet

    private var modeTransactionConstant: UInt32 {
        UInt32(TheOpenNetworkSendMode.payFeesSeparately.rawValue | TheOpenNetworkSendMode.ignoreActionPhaseErrors.rawValue)
    }

    // MARK: - Init

    init(wallet: Wallet) {
        self.wallet = wallet
    }

    // MARK: - Implementation

    /// Build input for sign transaction from Parameters
    func buildForSign(buildInput: TONTransactionInput) throws -> Data {
        let input = try input(
            amount: buildInput.amount,
            destination: buildInput.destination,
            expireAt: buildInput.expireAt,
            jettonWalletAddress: buildInput.jettonWalletAddress,
            params: buildInput.params,
            sequenceNumber: sequenceNumber
        )

        return try preSignData(from: input).dataToSign
    }

    /// Build input for sign transaction from compiled transaction (usually obtained from StakeKit)
    func buildCompiledForSign(
        transaction: TONCompiledTransaction,
        expireAt: UInt32
    ) throws -> TONPreSignData {
        let input = try input(
            amount: Amount(with: wallet.blockchain, value: transaction.amount / wallet.blockchain.decimalValue),
            destination: transaction.destination,
            expireAt: expireAt,
            params: TONTransactionParams(memo: transaction.comment),
            sequenceNumber: transaction.sequenceNumber,
            bounce: transaction.bounce
        )

        return try preSignData(from: input)
    }

    /// Creates PreSignData from transaction input
    private func preSignData(from txInput: TheOpenNetworkSigningInput) throws -> TONPreSignData {
        let txInputData = try txInput.serializedData()

        let preImageHashes = TransactionCompiler.preImageHashes(coinType: .ton, txInputData: txInputData)
        let preSigningOutput = try TxCompilerPreSigningOutput(serializedData: preImageHashes)

        guard preSigningOutput.error == .ok, !preSigningOutput.data.isEmpty else {
            BSDKLogger.error(error: "TONPreSigningOutput has a error: \(preSigningOutput.errorMessage)")
            throw NSError()
        }

        return TONPreSignData(dataToSign: preSigningOutput.data, serializedTransactionInput: txInputData)
    }

    /// Build for send transaction obtain external message output
    func buildForSend(buildInput: TONTransactionInput, signature: Data) throws -> String {
        let input = try input(
            amount: buildInput.amount,
            destination: buildInput.destination,
            expireAt: buildInput.expireAt,
            jettonWalletAddress: buildInput.jettonWalletAddress,
            params: buildInput.params,
            sequenceNumber: sequenceNumber
        )

        let txInputData = try input.serializedData()

        return try buildForSend(serializedInputData: txInputData, signature: signature)
    }

    func buildForSend(serializedInputData: Data, signature: Data) throws -> String {
        let compiledTransaction = TransactionCompiler.compileWithSignatures(
            coinType: .ton,
            txInputData: serializedInputData,
            signatures: signature.asDataVector(),
            publicKeys: wallet.publicKey.blockchainKey.asDataVector()
        )

        let signingOutput = try TheOpenNetworkSigningOutput(serializedData: compiledTransaction)

        guard signingOutput.error == .ok, !signingOutput.encoded.isEmpty else {
            BSDKLogger.error(error: "TONSigningOutput has a error: \(signingOutput.errorMessage)")
            throw WalletError.failedToBuildTx
        }

        return signingOutput.encoded
    }

    // MARK: - Private Implementation

    /// Build WalletCore input for sign transaction
    /// - Parameters:
    ///   - amount: Amount transaction
    ///   - destination: Destination address transaction
    ///   - jettonWalletAddress: Address of jetton wallet, required for jetton transaction
    ///   - expireAt: Date expired transaction .now + 60 default value
    /// - Returns: TheOpenNetworkSigningInput for sign transaction with external signer
    private func input(
        amount: Amount,
        destination: String,
        expireAt: UInt32,
        jettonWalletAddress: String? = nil,
        params: TONTransactionParams?,
        sequenceNumber: Int,
        bounce: Bool = false
    ) throws -> TheOpenNetworkSigningInput {
        let transferMessage: TheOpenNetworkTransfer

        switch amount.type {
        case .coin, .reserve:
            transferMessage = try transfer(
                amountValue: amount.value,
                destination: destination,
                params: params,
                bounce: bounce
            )
        case .token(let token):
            guard let jettonWalletAddress else {
                BSDKLogger.error(error: "Wallet address must be set for jetton trasaction")
                throw WalletError.failedToBuildTx
            }

            let jettonTransfer = try jettonTransfer(
                amount: amount,
                destination: destination,
                token: token,
                params: params
            )

            transferMessage = try transfer(
                amountValue: Constants.jettonTransferProcessingFee,
                destination: jettonWalletAddress,
                params: params,
                bounce: bounce,
                jettonTransfer: jettonTransfer
            )
        case .feeResource:
            throw BlockchainSdkError.notImplemented
        }

        return TheOpenNetworkSigningInput.with {
            $0.messages = [transferMessage]
            $0.walletVersion = TheOpenNetworkWalletVersion.walletV4R2
            $0.sequenceNumber = UInt32(sequenceNumber)
            $0.expireAt = expireAt
            $0.publicKey = wallet.publicKey.blockchainKey
        }
    }

    /// Create transfer message transaction to blockchain
    /// - Parameters:
    ///   - amount: Amount transaction
    ///   - destination: Destination address transaction
    /// - Returns: TheOpenNetworkTransfer message for Input transaction of TON blockchain
    private func transfer(
        amountValue: Decimal,
        destination: String,
        params: TONTransactionParams?,
        bounce: Bool = false,
        jettonTransfer: TheOpenNetworkJettonTransfer? = nil
    ) throws -> TheOpenNetworkTransfer {
        TheOpenNetworkTransfer.with {
            $0.dest = destination
            $0.amount = (amountValue * wallet.blockchain.decimalValue).uint64Value
            $0.mode = modeTransactionConstant
            $0.bounceable = bounce
            $0.comment = params?.memo ?? ""

            if let jettonTransfer {
                $0.jettonTransfer = jettonTransfer
            }
        }
    }

    /// Create jetton transfer message transaction to blockchain
    /// - Parameters:
    ///   - amount: Amount transaction
    ///   - destination: Destination address transaction
    /// - Returns: TheOpenNetworkTransfer message for Input transaction of TON blockchain
    private func jettonTransfer(
        amount: Amount,
        destination: String,
        token: Token,
        params: TONTransactionParams?
    ) throws -> TheOpenNetworkJettonTransfer {
        let jettonAmountPayload = try jettonAmountPayload(from: amount, tokenDecimalValue: token.decimalValue)

        return TheOpenNetworkJettonTransfer.with {
            $0.jettonAmount = jettonAmountPayload
            $0.toOwner = destination
            $0.responseAddress = wallet.address
            $0.forwardAmount = 1 // needs some amount to send "jetton transfer notification", use minimum
        }
    }

    /// Converts given amount to a uint128 with big-endian byte order.
    private func jettonAmountPayload(from amount: Amount, tokenDecimalValue: Decimal) throws -> Data {
        let decimalAmountValue = amount.value * tokenDecimalValue

        guard let bigUIntValue = BigUInt(decimal: decimalAmountValue) else {
            throw WalletError.failedToBuildTx
        }

        let rawPayload = Data(bigUIntValue.serialize())

        return rawPayload
    }
}

struct TONPreSignData {
    /// pre-image data obtained from TxCompilerPreSigningOutput -> data
    let dataToSign: Data
    /// TheOpenNetworkSigningInput -> serializedData()
    let serializedTransactionInput: Data
}

extension TONTransactionBuilder {
    enum Constants {
        static let jettonTransferProcessingFee: Decimal = 0.05 // used to cover token transfer fees, commonly used value after TON fee reduction, actual costs now are ~10 times less, excess is returned
    }
}
