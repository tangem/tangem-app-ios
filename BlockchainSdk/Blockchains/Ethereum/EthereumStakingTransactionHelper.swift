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

    func prepareForSign(_ stakingTransaction: StakingTransaction) throws -> Data {
        let input = try buildSigningInput(stakingTransaction: stakingTransaction)
        let preSigningOutput = try transactionBuilder.buildTxCompilerPreSigningOutput(input: input)
        return preSigningOutput.dataHash
    }

    func prepareForSend(
        stakingTransaction: StakingTransaction,
        signatureInfo: SignatureInfo
    ) throws -> Data {
        let input = try buildSigningInput(stakingTransaction: stakingTransaction)
        let output = try transactionBuilder.buildSigningOutput(input: input, signatureInfo: signatureInfo)
        return output.encoded
    }

    private func buildSigningInput(
        stakingTransaction: StakingTransaction
    ) throws -> EthereumSigningInput {
        let compiledTransaction: EthereumCompiledTransaction

        switch stakingTransaction.unsignedData {
        case let transaction as EthereumCompiledTransaction:
            compiledTransaction = transaction
        case let string as String:
            guard let compiledTransactionData = string.data(using: .utf8) else {
                throw EthereumTransactionBuilderError.invalidStakingTransaction
            }
            compiledTransaction = try JSONDecoder()
                .decode(EthereumCompiledTransaction.self, from: compiledTransactionData)
        default:
            throw EthereumTransactionBuilderError.invalidStakingTransaction
        }

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
                stakingTransaction.fee.amount,
                parameters: feeParameters
            ),
            nonce: compiledTransaction.nonce,
            data: data
        )
    }
}
