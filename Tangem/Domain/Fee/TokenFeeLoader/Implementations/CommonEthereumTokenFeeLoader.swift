//
//  CommonEthereumTokenFeeLoader.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress
import BlockchainSdk
import BigInt
import TangemFoundation

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

    func getFee(
        amount: BSDKAmount,
        destination: String,
        txData: Data,
        otherNativeFee: Decimal?,
        approveInput: ApproveWithSwapInput?
    ) async throws -> [BSDKFee] {
        guard let approveInput else {
            return try await estimateFees(amount: amount, destination: destination, txData: txData, otherNativeFee: otherNativeFee, stateOverride: nil)
        }

        // The swap gas estimate would revert while the allowance is missing, so it runs
        // with the allowance overridden to unlimited — covering the `transferFrom` gas.
        let unlimitedAllowanceOverride = EthereumAccountOverride.unlimitedAllowance(
            tokenAddress: approveInput.tokenContractAddress,
            owner: approveInput.owner,
            spender: approveInput.spender
        )

        // Both estimates run through this loader, so the approve fee is always
        // denominated in this loader's fee currency.
        async let swapFeesTask = estimateFees(
            amount: amount,
            destination: destination,
            txData: txData,
            otherNativeFee: otherNativeFee,
            stateOverride: unlimitedAllowanceOverride
        )
        async let approveFeesTask = estimateFees(
            amount: BSDKAmount(with: feeBlockchain, type: .coin, value: 0),
            destination: approveInput.tokenContractAddress,
            txData: approveInput.txData,
            otherNativeFee: nil,
            stateOverride: nil
        )

        let (swapFees, approveFees) = try await (swapFeesTask, approveFeesTask)

        // Approve never shows a speed selector — only the market fee is needed.
        // [safe: 1] = market for EIP-1559 (3 fees), fallback to [safe: 0] for single-fee.
        guard let marketApproveFee = approveFees[safe: 1] ?? approveFees[safe: 0] else {
            throw TokenFeeLoaderError.approveFeeNotFound
        }

        let combinedSwapAndApproveFees = swapFees.map { swapFee in
            var combinedFeeAmount = swapFee.amount
            combinedFeeAmount.value += marketApproveFee.amount.value

            guard let swapParameters = swapFee.parameters as? any EthereumFeeParameters else {
                return BSDKFee(combinedFeeAmount, parameters: swapFee.parameters)
            }

            return BSDKFee(
                combinedFeeAmount,
                parameters: ApproveWithSwapFeeParameters(swapParameters: swapParameters, approveFee: marketApproveFee)
            )
        }

        return combinedSwapAndApproveFees
    }
}

// MARK: - Private

private extension CommonEthereumTokenFeeLoader {
    func estimateFees(
        amount: BSDKAmount,
        destination: String,
        txData: Data,
        otherNativeFee: Decimal?,
        stateOverride: [String: EthereumAccountOverride]?
    ) async throws -> [BSDKFee] {
        var fees = try await ethereumNetworkProvider
            .getFee(destination: destination, value: amount.encodedForSend, data: txData, stateOverride: stateOverride)
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
    func estimatedFee(amount: Decimal) async throws -> [BSDKFee] {
        try await tokenFeeLoader.estimatedFee(amount: amount)
    }

    func getFee(amount: Decimal, destination: String) async throws -> [BSDKFee] {
        try await tokenFeeLoader.getFee(amount: amount, destination: destination)
    }
}
