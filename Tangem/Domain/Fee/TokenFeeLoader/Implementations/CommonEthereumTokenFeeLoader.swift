//
//  CommonEthereumTokenFeeLoader.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import BigInt

struct CommonEthereumTokenFeeLoader {
    let tokenItem: TokenItem
    let tokenFeeLoader: any TokenFeeLoader

    let ethereumNetworkProvider: any EthereumNetworkProvider
    let gaslessTransactionFeeProvider: any GaslessTransactionFeeProvider
}

// MARK: - TokenFeeLoader

extension CommonEthereumTokenFeeLoader: EthereumTokenFeeLoader {
    func estimatedFee(estimatedGasLimit: Int) async throws -> BSDKFee {
        let parameters = try await ethereumNetworkProvider.getFee(
            gasLimit: BigUInt(estimatedGasLimit),
            supportsEIP1559: tokenItem.blockchain.supportsEIP1559
        )

        let amount = parameters.calculateFee(decimalValue: tokenItem.blockchain.decimalValue)
        let feeAmount = BSDKAmount(with: tokenItem.blockchain, type: .coin, value: amount)

        return Fee(feeAmount)
    }

    func getFee(amount: BSDKAmount, destination: String, txData: Data) async throws -> [BSDKFee] {
        var fees = try await ethereumNetworkProvider
            .getFee(destination: destination, value: amount.encodedForSend, data: txData)
            .async()

        // For EVM networks increase gas limit
        fees = fees.map {
            $0.increasingGasLimit(
                byPercents: EthereumFeeParametersConstants.defaultGasLimitIncreasePercent,
                blockchain: tokenItem.blockchain,
                decimalValue: tokenItem.blockchain.decimalValue
            )
        }

        return fees
    }

    func getGaslessFee(amount: BSDKAmount, destination: String, txData: Data, feeToken: BSDKToken) async throws -> [BSDKFee] {
        // [REDACTED_TODO_COMMENT]

        let fee = try await gaslessTransactionFeeProvider
            .getGaslessFee(feeToken: feeToken, originalAmount: amount, originalDestination: destination)

        return [fee]
    }
}

// MARK: - TokenFeeLoader Proxy

extension CommonEthereumTokenFeeLoader: TokenFeeLoader {
    var allowsFeeSelection: Bool { tokenFeeLoader.allowsFeeSelection }

    func estimatedFee(amount: Decimal) async throws -> [BSDKFee] {
        try await tokenFeeLoader.estimatedFee(amount: amount)
    }

    func getFee(amount: Decimal, destination: String) async throws -> [BSDKFee] {
        try await tokenFeeLoader.getFee(amount: amount, destination: destination)
    }
}
