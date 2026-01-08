//
//  CommonSolanaTokenFeeLoader.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

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
    var allowsFeeSelection: Bool { tokenFeeLoader.allowsFeeSelection }

    func estimatedFee(amount: Decimal) async throws -> [BSDKFee] {
        try await tokenFeeLoader.estimatedFee(amount: amount)
    }

    func getFee(amount: Decimal, destination: String) async throws -> [BSDKFee] {
        try await tokenFeeLoader.getFee(amount: amount, destination: destination)
    }
}
