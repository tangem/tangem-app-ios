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
}
