//
//  EthereumStakingTransactionHelper.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore
import BigInt
import TangemFoundation

struct EthereumStakingTransactionHelper {
    private let transactionBuilder: EthereumTransactionBuilder
    private let mapper = EthereumTransactionMapper()

    init(transactionBuilder: EthereumTransactionBuilder) {
        self.transactionBuilder = transactionBuilder
    }

    func prepareForSign(_ stakeKitTransaction: StakeKitTransaction) throws -> Data {
        let compiledTransaction = try mapper.mapStakeKitTransaction(stakeKitTransaction)
        let input = try buildSigningInput(compiledTransaction: compiledTransaction, fee: stakeKitTransaction.fee)
        let preSigningOutput = try transactionBuilder.buildTxCompilerPreSigningOutput(input: input)
        return preSigningOutput.dataHash
    }

    func prepareForSend(
        stakeKitTransaction: StakeKitTransaction,
        signatureInfo: SignatureInfo
    ) throws -> Data {
        let compiledTransaction = try mapper.mapStakeKitTransaction(stakeKitTransaction)
        let input = try buildSigningInput(compiledTransaction: compiledTransaction, fee: stakeKitTransaction.fee)
        let output = try transactionBuilder.buildSigningOutput(input: input, signatureInfo: signatureInfo)
        return output.encoded
    }

    func prepareForSign(_ p2pTransaction: P2PTransaction) throws -> Data {
        let compiledTransaction = try mapper.mapP2PTransaction(p2pTransaction)
        let input = try buildSigningInput(compiledTransaction: compiledTransaction, fee: p2pTransaction.fee)
        let preSigningOutput = try transactionBuilder.buildTxCompilerPreSigningOutput(input: input)
        return preSigningOutput.dataHash
    }

    func prepareForSend(
        p2pTransaction: P2PTransaction,
        signatureInfo: SignatureInfo
    ) throws -> Data {
        let compiledTransaction = try mapper.mapP2PTransaction(p2pTransaction)
        let input = try buildSigningInput(compiledTransaction: compiledTransaction, fee: p2pTransaction.fee)
        let output = try transactionBuilder.buildSigningOutput(input: input, signatureInfo: signatureInfo)
        return output.encoded
    }

    private func buildSigningInput(
        compiledTransaction: EthereumCompiledTransaction,
        fee: Fee
    ) throws -> EthereumSigningInput {
        let coinAmount = compiledTransaction.value ?? .zero

        guard compiledTransaction.gasLimit > 0 else {
            throw EthereumTransactionBuilderError.feeParametersNotFound
        }

        let baseFee = compiledTransaction.maxFeePerGas ?? .zero
        let priorityFee = compiledTransaction.maxPriorityFeePerGas ?? .zero
        let gasPrice = compiledTransaction.gasPrice ?? .zero

        let feeParameters: FeeParameters

        if baseFee > 0, priorityFee > 0 {
            feeParameters = EthereumEIP1559FeeParameters(
                gasLimit: compiledTransaction.gasLimit,
                baseFee: baseFee,
                priorityFee: priorityFee
            )
        } else if gasPrice > 0 {
            feeParameters = EthereumLegacyFeeParameters(gasLimit: compiledTransaction.gasLimit, gasPrice: gasPrice)
        } else {
            throw EthereumTransactionBuilderError.feeParametersNotFound
        }

        let data = Data(hex: compiledTransaction.data)

        guard !data.isEmpty else {
            throw EthereumTransactionBuilderError.invalidStakingTransaction
        }

        return try transactionBuilder.buildSigningInput(
            destination: compiledTransaction.to,
            coinAmount: coinAmount,
            fee: Fee(
                fee.amount,
                parameters: feeParameters
            ),
            nonce: compiledTransaction.nonce,
            data: data
        )
    }
}
