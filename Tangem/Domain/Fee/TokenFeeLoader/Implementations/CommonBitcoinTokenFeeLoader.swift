//
//  CommonBitcoinTokenFeeLoader.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct CommonBitcoinTokenFeeLoader {
    let tokenItem: TokenItem
    let tokenFeeLoader: any TokenFeeLoader
}

// MARK: - BitcoinTokenFeeLoader

extension CommonBitcoinTokenFeeLoader: BitcoinTokenFeeLoader {
    func getFee(psbtBase64: String) async throws -> [BSDKFee] {
        let satoshi = try BitcoinPsbtSigningBuilder.fee(
            psbtBase64: psbtBase64,
            feeRateLimit: PsbtFeeRateLimit(blockchain: tokenItem.blockchain)
        )
        let value = Decimal(satoshi) / tokenItem.blockchain.decimalValue
        let amount = BSDKAmount(with: tokenItem.blockchain, type: .coin, value: value)
        return [BSDKFee(amount)]
    }
}

// MARK: - TokenFeeLoader Proxy

extension CommonBitcoinTokenFeeLoader: TokenFeeLoader {
    func estimatedFee(amount: Decimal) async throws -> [BSDKFee] {
        try await tokenFeeLoader.estimatedFee(amount: amount)
    }

    func getFee(amount: Decimal, destination: String) async throws -> [BSDKFee] {
        try await tokenFeeLoader.getFee(amount: amount, destination: destination)
    }

    func supports(_ input: TokenFeeProviderInputData) -> Bool {
        switch input {
        case .common, .cex, .dex(.bitcoinPsbt):
            return true
        case .dex(.ethereum), .dex(.ethereumEstimate), .dex(.solana), .dex(.tron), .approve, .approveWithSwap:
            return false
        }
    }

    func loadFees(_ input: TokenFeeProviderInputData, feeBlockchain _: Blockchain) async throws -> [BSDKFee] {
        switch input {
        case .common(let amount, let destination):
            return try await getFee(amount: amount, destination: destination)
        case .cex(let amount):
            return try await estimatedFee(amount: amount)
        case .dex(.bitcoinPsbt(let psbtBase64)):
            return try await getFee(psbtBase64: psbtBase64)
        case .dex(.ethereum), .dex(.ethereumEstimate), .dex(.solana), .dex(.tron), .approve, .approveWithSwap:
            throw TokenFeeLoaderError.tokenFeeLoaderNotFound
        }
    }
}
