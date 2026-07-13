//
//  CommonTronTokenFeeLoader.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct CommonTronTokenFeeLoader {
    let tokenFeeLoader: any TokenFeeLoader
    let tronDexTransactionFeeProvider: any TronDexTransactionFeeProvider
}

// MARK: - TronTokenFeeLoader

extension CommonTronTokenFeeLoader: TronTokenFeeLoader {
    func getFee(amount: BSDKAmount, destination: String, txData: Data, otherNativeFee: Decimal?) async throws -> [BSDKFee] {
        let fees = try await tronDexTransactionFeeProvider.getFee(amount: amount, destination: destination, callData: txData)

        guard let otherNativeFee, otherNativeFee > 0 else {
            return fees
        }

        // Increase fee value for native value. Will be spent similarly to a fee. Applicable to DEX-Bridge.
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
