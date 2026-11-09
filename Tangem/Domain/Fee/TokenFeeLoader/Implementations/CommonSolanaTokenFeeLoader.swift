//
//  CommonSolanaTokenFeeLoader.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct CommonSolanaTokenFeeLoader {
    let tokenFeeLoader: any TokenFeeLoader
    let compiledTransactionFeeProvider: any CompiledTransactionFeeProvider
}

// MARK: - SolanaTokenFeeLoader

extension CommonSolanaTokenFeeLoader: SolanaTokenFeeLoader {
    func getFee(compiledTransaction data: Data) async throws -> [BSDKFee] {
        let fees = try await compiledTransactionFeeProvider.getFee(compiledTransaction: data)
        return fees
    }
}

// MARK: - TokenFeeLoader Proxy

extension CommonSolanaTokenFeeLoader: TokenFeeLoader {
    func estimatedFee(amount: Decimal) async throws -> [BSDKFee] {
        try await tokenFeeLoader.estimatedFee(amount: amount)
    }

    func getFee(amount: Decimal, destination: String) async throws -> [BSDKFee] {
        try await tokenFeeLoader.getFee(amount: amount, destination: destination)
    }

    func supports(_ input: TokenFeeProviderInputData) -> Bool {
        switch input {
        case .common, .cex, .dex(.solana):
            return true
        case .dex(.ethereum), .dex(.ethereumEstimate), .dex(.bitcoinPsbt), .dex(.tron), .approve, .approveWithSwap:
            return false
        }
    }

    func loadFees(_ input: TokenFeeProviderInputData, feeBlockchain _: Blockchain) async throws -> [BSDKFee] {
        switch input {
        case .common(let amount, let destination):
            return try await getFee(amount: amount, destination: destination)
        case .cex(let amount):
            return try await estimatedFee(amount: amount)
        case .dex(.solana(let data)):
            return try await getFee(compiledTransaction: data)
        case .dex(.ethereum), .dex(.ethereumEstimate), .dex(.bitcoinPsbt), .dex(.tron), .approve, .approveWithSwap:
            throw TokenFeeLoaderError.tokenFeeLoaderNotFound
        }
    }
}
