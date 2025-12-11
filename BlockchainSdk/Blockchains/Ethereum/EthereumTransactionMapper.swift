//
//  EthereumTransactionMapper.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

struct EthereumTransactionMapper {
    func mapStakeKitTransaction(_ transaction: StakeKitTransaction) throws -> EthereumCompiledTransaction {
        guard let compiledTransactionData = transaction.unsignedData.data(using: .utf8) else {
            throw EthereumTransactionBuilderError.invalidStakingTransaction
        }
        let ethereumStakeKitTransaction = try JSONDecoder().decode(
            EthereumCompiledTransactionData.self,
            from: compiledTransactionData
        )

        return EthereumCompiledTransaction(
            from: ethereumStakeKitTransaction.from,
            gasLimit: BigUInt(Data(hex: ethereumStakeKitTransaction.gasLimit)),
            to: ethereumStakeKitTransaction.to,
            data: ethereumStakeKitTransaction.data,
            nonce: ethereumStakeKitTransaction.nonce,
            maxFeePerGas: ethereumStakeKitTransaction.maxFeePerGas.flatMap { BigUInt(Data(hex: $0)) },
            maxPriorityFeePerGas: ethereumStakeKitTransaction.maxPriorityFeePerGas.flatMap { BigUInt(Data(hex: $0)) },
            gasPrice: ethereumStakeKitTransaction.gasPrice.flatMap { BigUInt(Data(hex: $0)) },
            chainId: ethereumStakeKitTransaction.chainId,
            value: ethereumStakeKitTransaction.value.flatMap { BigUInt(Data(hex: $0)) }
        )
    }

    func mapP2PTransaction(_ transaction: P2PTransaction) throws -> EthereumCompiledTransaction {
        guard let gasLimit = BigUInt(transaction.unsignedData.gasLimit),
              let maxFeePerGas = transaction.unsignedData.maxFeePerGas.flatMap({ BigUInt($0) }),
              let maxPriorityFeePerGas = transaction.unsignedData.maxPriorityFeePerGas.flatMap({ BigUInt($0) }) else {
            throw EthereumTransactionBuilderError.invalidStakingTransaction
        }

        return EthereumCompiledTransaction(
            from: transaction.unsignedData.from,
            gasLimit: gasLimit,
            to: transaction.unsignedData.to,
            data: transaction.unsignedData.data,
            nonce: transaction.unsignedData.nonce,
            maxFeePerGas: maxFeePerGas,
            maxPriorityFeePerGas: maxPriorityFeePerGas,
            gasPrice: nil,
            chainId: transaction.unsignedData.chainId,
            value: transaction.unsignedData.value.flatMap { BigUInt($0) } ?? .zero,
        )
    }
}
