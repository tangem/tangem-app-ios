//
//  CommonTokenFeeProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation

class CommonTokenFeeProvider {
    let feeTokenItem: TokenItem
    let tokenFeeLoader: any TokenFeeLoader
    let stateSubject: CurrentValueSubject<TokenFeeProviderState, Never> = .init(.idle)

    init(feeTokenItem: TokenItem, tokenFeeLoader: any TokenFeeLoader) {
        self.tokenFeeLoader = tokenFeeLoader
        self.feeTokenItem = feeTokenItem
    }
}

// MARK: - TokenFeeProvider

extension CommonTokenFeeProvider: TokenFeeProvider {
    var state: TokenFeeProviderState { stateSubject.value }
    var statePublisher: AnyPublisher<TokenFeeProviderState, Never> { stateSubject.eraseToAnyPublisher() }
}

// MARK: - SimpleTokenFeeProvider

extension CommonTokenFeeProvider: SimpleTokenFeeProvider {
    func updateFees(amount: Decimal, destination: String) async {
        do {
            stateSubject.send(.loading)
            let fees = try await tokenFeeLoader.getFee(amount: amount, destination: destination)
            try Task.checkCancellation()
            stateSubject.send(.available(fees))
        } catch {
            stateSubject.send(.error(error))
        }
    }
}

// MARK: - CEXTokenFeeProvider

extension CommonTokenFeeProvider: CEXTokenFeeProvider {
    func updateFees(amount: Decimal) async {
        do {
            stateSubject.send(.loading)
            let fees = try await tokenFeeLoader.estimatedFee(amount: amount)
            try Task.checkCancellation()
            stateSubject.send(.available(fees))
        } catch {
            stateSubject.send(.error(error))
        }
    }
}

// MARK: - EthereumDEXTokenFeeProvider

extension CommonTokenFeeProvider: EthereumDEXTokenFeeProvider {
    func updateFees(amount: BSDKAmount, destination: String, txData: Data) async {
        do {
            stateSubject.send(.loading)
            let fees = try await tokenFeeLoader.asEthereumTokenFeeLoader().getFee(amount: amount, destination: destination, txData: txData)
            try Task.checkCancellation()
            stateSubject.send(.available(fees))
        } catch TokenFeeLoaderError.ethereumTokenFeeLoaderNotFound {
            stateSubject.send(.unavailable(.notSupported))
        } catch {
            stateSubject.send(.error(error))
        }
    }
}

// MARK: - SolanaDEXTokenFeeProvider

extension CommonTokenFeeProvider: SolanaDEXTokenFeeProvider {
    func updateFees(compiledTransaction data: Data) async {
        do {
            stateSubject.send(.loading)
            let fees = try await tokenFeeLoader.asSolanaTokenFeeLoader().getFee(compiledTransaction: data)
            try Task.checkCancellation()
            stateSubject.send(.available(fees))
        } catch TokenFeeLoaderError.solanaTokenFeeLoaderNotFound {
            stateSubject.send(.unavailable(.notSupported))
        } catch {
            stateSubject.send(.error(error))
        }
    }
}
