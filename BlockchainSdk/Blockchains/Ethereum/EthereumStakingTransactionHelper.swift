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

    init(transactionBuilder: EthereumTransactionBuilder) {
        self.transactionBuilder = transactionBuilder
    }

    func prepareForSign(_ stakingTransaction: StakeKitTransaction) throws -> Data {
        let compiledTransaction = try compiledTransaction(from: stakingTransaction)
        let input = try buildSigningInput(compiledTransaction: compiledTransaction, fee: stakingTransaction.fee)
        let preSigningOutput = try transactionBuilder.buildTxCompilerPreSigningOutput(input: input)
        return preSigningOutput.dataHash
    }

    func prepareForSend(
        stakingTransaction: StakeKitTransaction,
        signatureInfo: SignatureInfo
    ) throws -> Data {
        let compiledTransaction = try compiledTransaction(from: stakingTransaction)
        let input = try buildSigningInput(compiledTransaction: compiledTransaction, fee: stakingTransaction.fee)
        let output = try transactionBuilder.buildSigningOutput(input: input, signatureInfo: signatureInfo)
        return output.encoded
    }

    func prepareForSign(_ stakingTransaction: P2PTransaction) throws -> Data {
        let input = try buildSigningInput(compiledTransaction: stakingTransaction.unsignedData, fee: stakingTransaction.fee)
        let preSigningOutput = try transactionBuilder.buildTxCompilerPreSigningOutput(input: input)
        return preSigningOutput.dataHash
    }

    func prepareForSend(
        stakingTransaction: P2PTransaction,
        signatureInfo: SignatureInfo
    ) throws -> Data {
        let input = try buildSigningInput(compiledTransaction: stakingTransaction.unsignedData, fee: stakingTransaction.fee)
        let output = try transactionBuilder.buildSigningOutput(input: input, signatureInfo: signatureInfo)
        return output.encoded
    }

    private func compiledTransaction(
        from stakeKitTransaction: StakeKitTransaction
    ) throws -> EthereumCompiledTransaction {
        guard let compiledTransactionData = stakeKitTransaction.unsignedData.data(using: .utf8) else {
            throw EthereumTransactionBuilderError.invalidStakingTransaction
        }
        return try JSONDecoder()
            .decode(EthereumCompiledTransaction.self, from: compiledTransactionData)
    }

    private func buildSigningInput(
        compiledTransaction: EthereumCompiledTransaction,
        fee: Fee
    ) throws -> EthereumSigningInput {
        let coinAmount: BigUInt = compiledTransaction.value.flatMap { BigUInt($0) } ?? .zero

        guard let gasLimit = BigUInt(compiledTransaction.gasLimit), gasLimit > 0 else {
            throw EthereumTransactionBuilderError.feeParametersNotFound
        }

        let baseFee = compiledTransaction.maxFeePerGas.flatMap { BigUInt(Data(hex: $0)) } ?? .zero
        let priorityFee = compiledTransaction.maxPriorityFeePerGas.flatMap { BigUInt($0) } ?? .zero
        let gasPrice = compiledTransaction.gasPrice.flatMap { BigUInt($0) } ?? .zero

        let feeParameters: FeeParameters

        if baseFee > 0, priorityFee > 0 {
            feeParameters = EthereumEIP1559FeeParameters(gasLimit: gasLimit, baseFee: baseFee, priorityFee: priorityFee)
        } else if gasPrice > 0 {
            feeParameters = EthereumLegacyFeeParameters(gasLimit: gasLimit, gasPrice: gasPrice)
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
