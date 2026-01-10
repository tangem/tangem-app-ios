//
//  TokenFeeProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

extension WalletModel {
    var tokenFeeProvider: any TokenFeeProvider {
        CommonTokenFeeProvider(
            feeTokenItem: feeTokenItem,
            tokenFeeLoader: tokenFeeLoader,
            customFeeProvider: customFeeProvider
        )
    }
}

protocol TokenFeeProvider: AnyObject {
    var feeTokenItem: TokenItem { get }

    var state: TokenFeeProviderState { get }
    var statePublisher: AnyPublisher<TokenFeeProviderState, Never> { get }

    var fees: [TokenFee] { get }
    var feesPublisher: AnyPublisher<[TokenFee], Never> { get }
}

enum TokenFeeProviderState {
    case idle
    case unavailable(TokenFeeProviderStateUnavailableReason)
    case loading
    case error(Error)
    case available([BSDKFee])
}

enum TokenFeeProviderStateUnavailableReason {
    case notSupported
    case notEnoughFeeBalance
}

// MARK: - Variants

protocol SimpleTokenFeeProvider: TokenFeeProvider {
    func updateFees(amount: Decimal, destination: String) async
}

protocol CEXTokenFeeProvider: SimpleTokenFeeProvider {
    func updateFees(amount: Decimal) async
}

protocol DEXTokenFeeProvider: SimpleTokenFeeProvider {}

protocol EthereumDEXTokenFeeProvider: DEXTokenFeeProvider {
    func updateFees(amount: BSDKAmount, destination: String, txData: Data) async
}

protocol GasleesTokenFeeProvider: DEXTokenFeeProvider {
    func updateFees(amount: BSDKAmount, destination: String, txData: Data) async
}

protocol SolanaDEXTokenFeeProvider: DEXTokenFeeProvider {
    func updateFees(compiledTransaction data: Data) async
}

// MARK: - TokenFeeLoader+

extension TokenFeeProvider {
    func cast<FeeProvider>(_ type: FeeProvider.Type = FeeProvider.self) throws -> FeeProvider {
        guard let provider = self as? FeeProvider else {
            throw TokenFeeProviderError.tokenFeeProviderNotFound(name: "\(FeeProvider.self)")
        }

        return provider
    }

    func asSimpleTokenFeeProvider() throws -> SimpleTokenFeeProvider {
        try cast(SimpleTokenFeeProvider.self)
    }

    func asSolanaTokenFeeLoader() throws -> SolanaTokenFeeLoader {
        guard let solanaTokenFeeLoader = self as? SolanaTokenFeeLoader else {
            throw TokenFeeLoaderError.solanaTokenFeeLoaderNotFound
        }

        return solanaTokenFeeLoader
    }
}

enum TokenFeeProviderError: LocalizedError {
    case tokenFeeProviderNotFound(name: String)

    var errorDescription: String? {
        switch self {
        case .tokenFeeProviderNotFound(name: let name): "TokenFeeProvider for \(name) not found"
        }
    }
}
