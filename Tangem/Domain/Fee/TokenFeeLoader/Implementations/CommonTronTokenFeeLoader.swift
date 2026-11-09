//
//  CommonTronTokenFeeLoader.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemExpress

struct CommonTronTokenFeeLoader {
    let tokenFeeLoader: any TokenFeeLoader
    let tronTransactionFeeProvider: any TronTransactionFeeProvider
}

// MARK: - TronTokenFeeLoader

extension CommonTronTokenFeeLoader: TronTokenFeeLoader {
    func getFee(request: TronFeeRequestData) async throws -> [BSDKFee] {
        let fees = try await tronTransactionFeeProvider.getFee(
            amount: request.amount,
            destination: request.destination,
            callData: request.callData,
            memo: request.memo
        )

        guard let otherNativeFee = request.otherNativeFee, otherNativeFee > 0 else {
            return fees
        }

        // Increase fee value for native value. Will be spent similarly to a fee. Applicable to DEX-Bridge.
        ExpressLogger.info("The Tron fee was increased by otherNativeFee \(otherNativeFee)")

        return fees.map { fee in
            var fee = fee
            fee.amount.value += otherNativeFee
            return fee
        }
    }
}

// MARK: - TokenFeeLoader Proxy

extension CommonTronTokenFeeLoader: TokenFeeLoader {
    func estimatedFee(amount: Decimal) async throws -> [BSDKFee] {
        try await tokenFeeLoader.estimatedFee(amount: amount)
    }

    func getFee(amount: Decimal, destination: String) async throws -> [BSDKFee] {
        try await tokenFeeLoader.getFee(amount: amount, destination: destination)
    }

    func supports(_ input: TokenFeeProviderInputData) -> Bool {
        supportsTronFeeInput(input)
    }

    func loadFees(_ input: TokenFeeProviderInputData, feeBlockchain: Blockchain) async throws -> [BSDKFee] {
        try await loadTronFees(input, feeBlockchain: feeBlockchain)
    }
}

extension TronTokenFeeLoader {
    func supportsTronFeeInput(_ input: TokenFeeProviderInputData) -> Bool {
        switch input {
        case .common, .cex, .dex(.tron), .approve:
            return true
        case .dex(.ethereum), .dex(.ethereumEstimate), .dex(.solana), .dex(.bitcoinPsbt), .approveWithSwap:
            return false
        }
    }

    func loadTronFees(_ input: TokenFeeProviderInputData, feeBlockchain: Blockchain) async throws -> [BSDKFee] {
        switch input {
        case .common(let amount, let destination):
            return try await getFee(amount: amount, destination: destination)
        case .cex(let amount):
            return try await estimatedFee(amount: amount)
        case .dex(.tron(let request, _, _)):
            return try await getFee(request: request)
        case .approve(let txData, let toContractAddress, _, _, _):
            let zeroAmount = BSDKAmount(with: feeBlockchain, type: .coin, value: 0)
            return try await getFee(request: TronFeeRequestData(
                amount: zeroAmount,
                destination: toContractAddress,
                callData: txData,
                memo: nil,
                otherNativeFee: nil
            ))
        case .dex(.ethereum), .dex(.ethereumEstimate), .dex(.solana), .dex(.bitcoinPsbt), .approveWithSwap:
            throw TokenFeeLoaderError.tokenFeeLoaderNotFound
        }
    }
}
