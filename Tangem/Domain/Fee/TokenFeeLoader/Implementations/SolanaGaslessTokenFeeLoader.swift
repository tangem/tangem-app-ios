//
//  SolanaGaslessTokenFeeLoader.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct SolanaGaslessTokenFeeLoader {
    private let networkFeeLoader: any TokenFeeLoader
    private let feeTokenItem: TokenItem
    private let feePayerProvider: () async -> String?

    init(
        networkFeeLoader: any TokenFeeLoader,
        feeTokenItem: TokenItem,
        feePayerProvider: @escaping () async -> String?
    ) {
        self.networkFeeLoader = networkFeeLoader
        self.feeTokenItem = feeTokenItem
        self.feePayerProvider = feePayerProvider
    }
}

// MARK: - TokenFeeLoader

extension SolanaGaslessTokenFeeLoader: TokenFeeLoader {
    func estimatedFee(amount: Decimal) async throws -> [BSDKFee] {
        let fees = try await networkFeeLoader.estimatedFee(amount: amount)
        return try await mapToSponsoredFees(networkFees: fees)
    }

    func getFee(amount: Decimal, destination: String) async throws -> [BSDKFee] {
        let fees = try await networkFeeLoader.getFee(amount: amount, destination: destination)
        return try await mapToSponsoredFees(networkFees: fees)
    }

    func supports(_ input: TokenFeeProviderInputData) -> Bool {
        networkFeeLoader.supports(input)
    }

    func loadFees(_ input: TokenFeeProviderInputData, feeBlockchain: Blockchain) async throws -> [BSDKFee] {
        guard supports(input) else {
            throw TokenFeeLoaderError.tokenFeeLoaderNotFound
        }

        let fees = try await networkFeeLoader.loadFees(input, feeBlockchain: feeBlockchain)
        return try await mapToSponsoredFees(networkFees: fees)
    }
}

// MARK: - Private

private extension SolanaGaslessTokenFeeLoader {
    func mapToSponsoredFees(networkFees: [BSDKFee]) async throws -> [BSDKFee] {
        guard let networkFee = networkFees.first else {
            throw TokenFeeProviderError.feeNotFound
        }

        guard let feePayer = await feePayerProvider() else {
            throw TokenFeeLoaderError.missingSolanaFeePayer
        }

        let parameters = SolanaGaslessFeeParameters(feePayer: feePayer, networkFee: networkFee)
        let amount = BSDKAmount(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: .zero)

        return [BSDKFee(amount, parameters: parameters)]
    }
}
