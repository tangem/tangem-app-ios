//
//  CommonEthereumTokenFeeLoader.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemExpress
import BlockchainSdk
import BigInt

struct CommonEthereumTokenFeeLoader {
    let feeBlockchain: Blockchain
    let tokenFeeLoader: any TokenFeeLoader
    let ethereumNetworkProvider: any EthereumNetworkProvider
}

// MARK: - EthereumTokenFeeLoader

extension CommonEthereumTokenFeeLoader: EthereumTokenFeeLoader {
    func estimatedFee(estimatedGasLimit: Int, otherNativeFee: Decimal?) async throws -> BSDKFee {
        let parameters = try await ethereumNetworkProvider.getFee(
            gasLimit: BigUInt(estimatedGasLimit),
            supportsEIP1559: feeBlockchain.supportsEIP1559
        )

        var feeAmount = parameters.calculateFee(decimalValue: feeBlockchain.decimalValue)

        // Increase fee value for native value. Will be spend similar like fee. Applicable to DEX-Bridge
        if let otherNativeFee {
            ExpressLogger.info("The estimatedFee was increased by otherNativeFee \(otherNativeFee)")
            feeAmount += otherNativeFee
        }

        return Fee(BSDKAmount(with: feeBlockchain, type: .coin, value: feeAmount), parameters: parameters)
    }

    func getFee(amount: BSDKAmount, destination: String, txData: Data, otherNativeFee: Decimal?) async throws -> [BSDKFee] {
        var fees = try await ethereumNetworkProvider
            .getFee(destination: destination, value: amount.encodedForSend, data: txData)
            .async()

        // For EVM networks increase gas limit
        fees = fees.map {
            $0.increasingGasLimit(
                byPercents: EthereumFeeParametersConstants.defaultGasLimitIncreasePercent,
                blockchain: feeBlockchain,
                decimalValue: feeBlockchain.decimalValue
            )
        }

        // Increase fee value for native value. Will be spend similar like fee. Applicable to DEX-Bridge
        if let otherNativeFee {
            ExpressLogger.info("The fee was increased by otherNativeFee \(otherNativeFee)")
            fees = fees.map { fee in
                BSDKFee(.init(with: fee.amount, value: fee.amount.value + otherNativeFee), parameters: fee.parameters)
            }
        }

        return fees
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
