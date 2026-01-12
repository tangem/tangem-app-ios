//
//  TokenFeeProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol TokenFeeProvider {
    var feeTokenItem: TokenItem { get }

    var state: TokenFeeProviderState { get }
    var statePublisher: AnyPublisher<TokenFeeProviderState, Never> { get }

    var fees: [TokenFee] { get }
    var feesPublisher: AnyPublisher<[TokenFee], Never> { get }
}

protocol LoadableTokenFeeProvider: TokenFeeProvider {
    func updateFees(amount: Decimal, destination: String) async
}

protocol CEXTokenFeeProvider: LoadableTokenFeeProvider {
    func updateFees(amount: Decimal) async
}

protocol EthereumDEXTokenFeeProvider: LoadableTokenFeeProvider {
    func updateFees(estimatedGasLimit: Int, otherNativeFee: Decimal?) async
    func updateFees(amount: BSDKAmount, destination: String, txData: Data, otherNativeFee: Decimal?) async
}

protocol GasleesTokenFeeProvider: LoadableTokenFeeProvider {
    func updateFees(amount: BSDKAmount, destination: String, txData: Data, otherNativeFee: Decimal?) async
}

protocol SolanaDEXTokenFeeProvider: LoadableTokenFeeProvider {
    func updateFees(compiledTransaction data: Data) async
}

// MARK: - Types

// MARK: - TokenFeeLoader+

extension TokenFeeProvider {
    func cast<FeeProvider>(_ type: FeeProvider.Type = FeeProvider.self) throws -> FeeProvider {
        guard let provider = self as? FeeProvider else {
            throw TokenFeeProviderError.tokenFeeProviderNotFound(name: "\(FeeProvider.self)")
        }

        return provider
    }

    func asSimpleTokenFeeProvider() throws -> LoadableTokenFeeProvider {
        try cast(LoadableTokenFeeProvider.self)
    }

    func asCEXTokenFeeProvider() throws -> CEXTokenFeeProvider {
        try cast(CEXTokenFeeProvider.self)
    }

    func asEthereumDEXTokenFeeProvider() throws -> EthereumDEXTokenFeeProvider {
        try cast(EthereumDEXTokenFeeProvider.self)
    }

    func asSolanaDEXTokenFeeProvider() throws -> SolanaDEXTokenFeeProvider {
        try cast(SolanaDEXTokenFeeProvider.self)
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
