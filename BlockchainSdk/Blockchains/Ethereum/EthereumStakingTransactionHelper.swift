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

struct EthereumStakingTransactionHelper {
    private let transactionBuilder: EthereumTransactionBuilder

    init(transactionBuilder: EthereumTransactionBuilder) {
        self.transactionBuilder = transactionBuilder
    }

    func prepareForSign(_ unsignedTransactionHex: String, fee: Fee) throws -> Data {
        let input = try buildSigningInput(unsignedTransactionHex: unsignedTransactionHex, fee: fee)
        let preSigningOutput = try transactionBuilder.buildTxCompilerPreSigningOutput(input: input)
        return preSigningOutput.dataHash
    }

    func prepareForSend(
        _ unsignedTransactionHex: String,
        fee: Fee,
        signatureInfo: SignatureInfo
    ) throws -> Data {
        let input = try buildSigningInput(unsignedTransactionHex: unsignedTransactionHex, fee: fee)
        let output = try transactionBuilder.buildSigningOutput(input: input, signatureInfo: signatureInfo)
        return output.encoded
    }

    private func buildSigningInput(
        unsignedTransactionHex: String,
        fee: Fee
    ) throws -> EthereumSigningInput {
        let compiledTransactionData = Data(hex: unsignedTransactionHex)

        let compiledTransaction = try JSONDecoder()
            .decode(EthereumCompiledTransaction.self, from: compiledTransactionData)

        let coinAmount: BigUInt = compiledTransaction.value.flatMap { BigUInt(Data(hex: $0)) } ?? .zero

        let gasLimit = BigUInt(Data(hex: compiledTransaction.gasLimit))
        guard gasLimit > 0 else {
            throw EthereumTransactionBuilderError.feeParametersNotFound
        }

        let baseFee = compiledTransaction.maxFeePerGas.flatMap { BigUInt(Data(hex: $0)) } ?? .zero
        let priorityFee = compiledTransaction.maxPriorityFeePerGas.flatMap { BigUInt(Data(hex: $0)) } ?? .zero
        let gasPrice = compiledTransaction.gasPrice.flatMap { BigUInt(Data(hex: $0)) } ?? .zero

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

public struct EthereumCompiledTransaction: Decodable {
    let from: String
    let gasLimit: String
    let to: String
    let data: String
    let nonce: Int
    let type: Int
    let maxFeePerGas: String?
    let maxPriorityFeePerGas: String?
    let gasPrice: String?
    let chainId: Int
    let value: String?
}
