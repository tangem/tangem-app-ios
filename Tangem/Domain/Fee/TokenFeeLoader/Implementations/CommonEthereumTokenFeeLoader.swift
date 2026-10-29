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
            blockchain: feeBlockchain
        )

        var feeAmount = parameters.calculateFee(decimalValue: feeBlockchain.decimalValue)

        // Increase fee value for native value. Will be spend similar like fee. Applicable to DEX-Bridge
        if let otherNativeFee {
            ExpressLogger.info("The estimatedFee was increased by otherNativeFee \(otherNativeFee)")
            feeAmount += otherNativeFee
        }

        return Fee(BSDKAmount(with: feeBlockchain, type: .coin, value: feeAmount), parameters: parameters)
    }

    func getFee(request: EthereumFeeRequestData) async throws -> [BSDKFee] {
        try await estimateFees(request: request, stateOverride: nil)
    }

    func getApproveWithSwapFee(request: EthereumFeeRequestData, approveInput: ApproveWithSwapInput) async throws -> [BSDKFee] {
        let unlimitedAllowanceOverride = EthereumAccountOverride.unlimitedAllowance(
            tokenAddress: approveInput.tokenContractAddress,
            owner: approveInput.owner,
            spender: approveInput.spender
        )

        let approveRequest = EthereumFeeRequestData(
            amount: BSDKAmount(with: feeBlockchain, type: .coin, value: 0),
            destination: approveInput.tokenContractAddress,
            txData: approveInput.txData,
            otherNativeFee: nil
        )

        async let swapFeesTask = estimateFees(request: request, stateOverride: unlimitedAllowanceOverride)
        async let approveFeesTask = estimateFees(request: approveRequest, stateOverride: nil)

        let (swapFees, approveFees) = try await (swapFeesTask, approveFeesTask)

        guard let marketApproveFee = approveFees[safe: 1] ?? approveFees[safe: 0] else {
            throw TokenFeeLoaderError.approveFeeNotFound
        }

        let increasedApproveFee = marketApproveFee.increasingGasPrice(
            byPercents: EthereumFeeParametersConstants.approveWithSwapGasPriceIncreasePercent,
            decimalValue: feeBlockchain.decimalValue
        )

        return try swapFees.map { swapFee in
            try ApproveWithSwapFeeParameters.combinedFee(swapFee: swapFee, approveFee: increasedApproveFee)
        }
    }
}

// MARK: - Private

private extension CommonEthereumTokenFeeLoader {
    func estimateFees(request: EthereumFeeRequestData, stateOverride: EthereumStateOverride?) async throws -> [BSDKFee] {
        var fees = try await ethereumNetworkProvider
            .getFee(destination: request.destination, value: request.amount.encodedForSend, data: request.txData, stateOverride: stateOverride)
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
        if let otherNativeFee = request.otherNativeFee {
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

    func supports(_ input: TokenFeeProviderInputData) -> Bool {
        supportsEthereumFeeInput(input)
    }

    func loadFees(_ input: TokenFeeProviderInputData, feeBlockchain: Blockchain) async throws -> [BSDKFee] {
        try await loadEthereumFees(input, feeBlockchain: feeBlockchain)
    }
}

extension EthereumTokenFeeLoader {
    func supportsEthereumFeeInput(_ input: TokenFeeProviderInputData) -> Bool {
        switch input {
        case .common, .cex, .dex(.ethereum), .dex(.ethereumEstimate), .approve, .approveWithSwap:
            return true
        case .dex(.solana), .dex(.bitcoinPsbt), .dex(.tron):
            return false
        }
    }

    func loadEthereumFees(_ input: TokenFeeProviderInputData, feeBlockchain: Blockchain) async throws -> [BSDKFee] {
        switch input {
        case .common(let amount, let destination):
            return try await getFee(amount: amount, destination: destination)
        case .cex(let amount):
            return try await estimatedFee(amount: amount)
        case .dex(.ethereumEstimate(let estimatedGasLimit, let otherNativeFee)):
            return [try await estimatedFee(estimatedGasLimit: estimatedGasLimit, otherNativeFee: otherNativeFee)]
        case .dex(.ethereum(let amount, let destination, let txData, let otherNativeFee)):
            return try await getFee(request: EthereumFeeRequestData(
                amount: amount,
                destination: destination,
                txData: txData,
                otherNativeFee: otherNativeFee
            ))
        case .approve(let txData, let toContractAddress, _, _, _):
            let zeroAmount = BSDKAmount(with: feeBlockchain, type: .coin, value: 0)
            return try await getFee(request: EthereumFeeRequestData(
                amount: zeroAmount,
                destination: toContractAddress,
                txData: txData,
                otherNativeFee: nil
            ))
        case .approveWithSwap(let amount, let destination, let txData, let otherNativeFee, let approve):
            return try await getApproveWithSwapFee(
                request: EthereumFeeRequestData(
                    amount: amount,
                    destination: destination,
                    txData: txData,
                    otherNativeFee: otherNativeFee
                ),
                approveInput: approve
            )
        case .dex(.solana), .dex(.bitcoinPsbt), .dex(.tron):
            throw TokenFeeLoaderError.tokenFeeLoaderNotFound
        }
    }
}
