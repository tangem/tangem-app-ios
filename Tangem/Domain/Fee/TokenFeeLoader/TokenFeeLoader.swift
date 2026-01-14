//
//  TokenFeeLoader.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol TokenFeeLoader {
    var allowsFeeSelection: Bool { get }

    func estimatedFee(amount: Decimal) async throws -> [BSDKFee]
    func getFee(amount: Decimal, destination: String) async throws -> [BSDKFee]
}

extension TokenFeeLoader {
    var supportingFeeOptions: [FeeOption] {
        allowsFeeSelection ? [.slow, .market, .fast] : [.market]
    }
}

// MARK: - EthereumTokenFeeLoader

protocol EthereumTokenFeeLoader: TokenFeeLoader {
    func estimatedFee(estimatedGasLimit: Int, otherNativeFee: Decimal?) async throws -> BSDKFee
    func getFee(amount: BSDKAmount, destination: String, txData: Data, otherNativeFee: Decimal?) async throws -> [BSDKFee]
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

    var errorDescription: String? {
        switch self {
        case .tokenFeeLoaderNotFound: "TokenFeeLoader not found"
        case .gaslessEthereumTokenFeeSupportOnlyTokenAsFeeTokenItem: "GaslessEthereumTokenFeeLoader supports only token as fee token item"
        case .feeTokenIdNotFound: "Fee token id not found"
        }
    }
}
