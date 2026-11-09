//
//  DefaultTokenFeeLoader.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

protocol TokenFeeLoading {
    func estimatedFee(amount: Decimal) async throws -> [BSDKFee]
    func getFee(amount: Decimal, destination: String) async throws -> [BSDKFee]
}

struct DefaultTokenFeeLoader {
    let loader: any TokenFeeLoading
}

extension DefaultTokenFeeLoader: TokenFeeLoader {
    func estimatedFee(amount: Decimal) async throws -> [BSDKFee] {
        try await loader.estimatedFee(amount: amount)
    }

    func getFee(amount: Decimal, destination: String) async throws -> [BSDKFee] {
        try await loader.getFee(amount: amount, destination: destination)
    }

    func supports(_ input: TokenFeeProviderInputData) -> Bool {
        switch input {
        case .common, .cex:
            true
        case .dex, .approve, .approveWithSwap:
            false
        }
    }

    func loadFees(_ input: TokenFeeProviderInputData, feeBlockchain _: Blockchain) async throws -> [BSDKFee] {
        switch input {
        case .common(let amount, let destination):
            try await getFee(amount: amount, destination: destination)
        case .cex(let amount):
            try await estimatedFee(amount: amount)
        case .dex, .approve, .approveWithSwap:
            throw TokenFeeLoaderError.tokenFeeLoaderNotFound
        }
    }
}
