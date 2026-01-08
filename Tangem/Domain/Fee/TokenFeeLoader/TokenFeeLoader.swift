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

// MARK: - Custom TokenFeeLoaders

protocol EthereumTokenFeeLoader: TokenFeeLoader {
    func estimatedFee(estimatedGasLimit: Int) async throws -> BSDKFee
    func getFee(amount: BSDKAmount, destination: String, txData: Data) async throws -> [BSDKFee]
    func getGaslessFee(amount: BSDKAmount, destination: String, txData: Data, feeToken: BSDKToken) async throws -> [BSDKFee]
}

protocol SolanaTokenFeeLoader: TokenFeeLoader {
    func getFee(compiledTransaction data: Data) async throws -> [BSDKFee]
}

// MARK: - TokenFeeLoader+

extension TokenFeeLoader {
    func asEthereumTokenFeeLoader() throws -> EthereumTokenFeeLoader {
        guard let ethereumTokenFeeLoader = self as? EthereumTokenFeeLoader else {
            throw TokenFeeLoaderError.ethereumTokenFeeLoaderNotFound
        }

        return ethereumTokenFeeLoader
    }

    func asSolanaTokenFeeLoader() throws -> SolanaTokenFeeLoader {
        guard let solanaTokenFeeLoader = self as? SolanaTokenFeeLoader else {
            throw TokenFeeLoaderError.solanaTokenFeeLoaderNotFound
        }

        return solanaTokenFeeLoader
    }
}

enum TokenFeeLoaderError: LocalizedError {
    case ethereumTokenFeeLoaderNotFound
    case solanaTokenFeeLoaderNotFound

    var errorDescription: String? {
        switch self {
        case .ethereumTokenFeeLoaderNotFound: "EthereumTokenFeeLoader not found"
        case .solanaTokenFeeLoaderNotFound: "SolanaTokenFeeLoader not found"
        }
    }
}
