//
//  TokenFeeLoader.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import struct BlockchainSdk.EthereumAccountOverride

protocol TokenFeeLoader {
    func estimatedFee(amount: Decimal) async throws -> [BSDKFee]
    func getFee(amount: Decimal, destination: String) async throws -> [BSDKFee]
}

// MARK: - EthereumTokenFeeLoader

protocol EthereumTokenFeeLoader: TokenFeeLoader {
    func estimatedFee(estimatedGasLimit: Int, otherNativeFee: Decimal?) async throws -> BSDKFee
    func getFee(amount: BSDKAmount, destination: String, txData: Data, otherNativeFee: Decimal?) async throws -> [BSDKFee]

    /// Override-aware variant for pre-approve `transferFrom` gas estimation; passes `stateOverride` down to
    /// `EthereumNetworkProvider.getFee`. Default impl drops the override so legacy loaders silently degrade.
    func getFee(
        amount: BSDKAmount,
        destination: String,
        txData: Data,
        otherNativeFee: Decimal?,
        stateOverride: [String: EthereumAccountOverride]?
    ) async throws -> [BSDKFee]
}

extension EthereumTokenFeeLoader {
    func getFee(
        amount: BSDKAmount,
        destination: String,
        txData: Data,
        otherNativeFee: Decimal?,
        stateOverride: [String: EthereumAccountOverride]?
    ) async throws -> [BSDKFee] {
        try await getFee(amount: amount, destination: destination, txData: txData, otherNativeFee: otherNativeFee)
    }
}

// MARK: - SolanaTokenFeeLoader

protocol SolanaTokenFeeLoader: TokenFeeLoader {
    func getFee(compiledTransaction data: Data) async throws -> [BSDKFee]
}

// MARK: - TokenFeeLoader+

extension TokenFeeLoader {
    func asEthereumTokenFeeLoader() throws -> EthereumTokenFeeLoader {
        guard let ethereumTokenFeeLoader = self as? EthereumTokenFeeLoader else {
            throw TokenFeeLoaderError.tokenFeeLoaderNotFound
        }

        return ethereumTokenFeeLoader
    }

    func asSolanaTokenFeeLoader() throws -> SolanaTokenFeeLoader {
        guard let solanaTokenFeeLoader = self as? SolanaTokenFeeLoader else {
            throw TokenFeeLoaderError.tokenFeeLoaderNotFound
        }

        return solanaTokenFeeLoader
    }
}

enum TokenFeeLoaderError: LocalizedError {
    case tokenFeeLoaderNotFound
    case gaslessEthereumTokenFeeSupportOnlyTokenAsFeeTokenItem
    case feeTokenIdNotFound
    case missingFeeRecipientAddress
    case gaslessExecutionReverted(gaslessMinTokenAmount: Decimal)
    case executionReverted

    var errorDescription: String? {
        switch self {
        case .tokenFeeLoaderNotFound: "TokenFeeLoader not found"
        case .gaslessEthereumTokenFeeSupportOnlyTokenAsFeeTokenItem: "GaslessEthereumTokenFeeLoader supports only token as fee token item"
        case .feeTokenIdNotFound: "Fee token id not found"
        case .missingFeeRecipientAddress: "Missing fee recipient address"
        case .gaslessExecutionReverted(let gaslessMinTokenAmount): "Gasless fee estimation execution reverted, min token amount: \(gaslessMinTokenAmount)"
        case .executionReverted: "Execution reverted"
        }
    }
}
