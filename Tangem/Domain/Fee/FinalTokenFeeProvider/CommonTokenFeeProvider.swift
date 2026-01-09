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
    private let tokenFeeLoader: any TokenFeeLoader
    private let customFeeProvider: (any CustomFeeProvider)?

    private let stateSubject: CurrentValueSubject<TokenFeeProviderState, Never> = .init(.idle)
    private var supportingFeeOption: [FeeOption] {
        var supportingFeeOption = tokenFeeLoader.supportingFeeOption

        if customFeeProvider != nil {
            supportingFeeOption.append(.custom)
        }

        return supportingFeeOption
    }

    init(feeTokenItem: TokenItem, tokenFeeLoader: any TokenFeeLoader, customFeeProvider: (any CustomFeeProvider)?) {
        self.tokenFeeLoader = tokenFeeLoader
        self.feeTokenItem = feeTokenItem
        self.customFeeProvider = customFeeProvider
    }
}

// MARK: - TokenFeeProvider

extension CommonTokenFeeProvider: TokenFeeProvider {
    var state: TokenFeeProviderState { stateSubject.value }
    var statePublisher: AnyPublisher<TokenFeeProviderState, Never> { stateSubject.eraseToAnyPublisher() }

    var fees: [TokenFee] {
        var fees = mapToTokenFees(state: state)

        if let customFee = customFeeProvider?.customFee {
            fees.append(customFee)
        }

        return fees
    }

    var feesPublisher: AnyPublisher<[TokenFee], Never> {
        let feesPublisher = statePublisher.withWeakCaptureOf(self).map { $0.mapToTokenFees(state: $1) }
        let customFeePublisher = customFeeProvider?.customFeePublisher.map { [$0] }.eraseToAnyPublisher() ?? Just([]).eraseToAnyPublisher()

        return Publishers
            .CombineLatest(feesPublisher, customFeePublisher)
            .map(+)
            .eraseToAnyPublisher()
    }

    private func mapToTokenFees(state: TokenFeeProviderState) -> [TokenFee] {
        switch state {
        case .idle, .unavailable: []
        case .loading:
            TokenFeeConverter.mapToLoadingSendFees(options: supportingFeeOption, feeTokenItem: feeTokenItem)
        case .error(let error):
            TokenFeeConverter.mapToFailureSendFees(options: supportingFeeOption, feeTokenItem: feeTokenItem, error: error)
        case .available(let fees):
            TokenFeeConverter.mapToSendFees(fees: fees, feeTokenItem: feeTokenItem)
        }
    }
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
