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
    let customFeeProvider: (any CustomFeeProvider)?

    private let stateSubject: CurrentValueSubject<TokenFeeProviderState, Never> = .init(.idle)
    private var customFeeProviderInitialSetupCancellable: AnyCancellable?

    init(
        feeTokenItem: TokenItem,
        tokenFeeLoader: any TokenFeeLoader,
        customFeeProvider: (any CustomFeeProvider)?
    ) {
        self.tokenFeeLoader = tokenFeeLoader
        self.feeTokenItem = feeTokenItem
        self.customFeeProvider = customFeeProvider

        bind()
    }

    private func bind() {
        customFeeProviderInitialSetupCancellable = customFeeProvider?.subscribeToInitialSetup(
            tokenFeeProvider: self
        )
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
            TokenFeeConverter.mapToLoadingSendFees(options: tokenFeeLoader.supportingFeeOptions, feeTokenItem: feeTokenItem)
        case .error(let error):
            TokenFeeConverter.mapToFailureSendFees(options: tokenFeeLoader.supportingFeeOptions, feeTokenItem: feeTokenItem, error: error)
        case .available(let fees):
            TokenFeeConverter.mapToSendFees(fees: fees, feeTokenItem: feeTokenItem)
        }
    }
}

// MARK: - FeeSelectorCustomFeeDataProviding

extension CommonTokenFeeProvider: FeeSelectorCustomFeeDataProviding {}

// MARK: - LoadableTokenFeeProvider

extension CommonTokenFeeProvider: LoadableTokenFeeProvider {
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
    func updateFees(estimatedGasLimit: Int, otherNativeFee: Decimal?) async {
        do {
            stateSubject.send(.loading)
            let fee = try await tokenFeeLoader.asEthereumTokenFeeLoader().estimatedFee(
                estimatedGasLimit: estimatedGasLimit,
                otherNativeFee: otherNativeFee
            )
            try Task.checkCancellation()
            stateSubject.send(.available([fee]))
        } catch TokenFeeLoaderError.ethereumTokenFeeLoaderNotFound {
            stateSubject.send(.unavailable(.notSupported))
        } catch {
            stateSubject.send(.error(error))
        }
    }

    func updateFees(amount: BSDKAmount, destination: String, txData: Data, otherNativeFee: Decimal?) async {
        do {
            stateSubject.send(.loading)
            let fees = try await tokenFeeLoader.asEthereumTokenFeeLoader().getFee(
                amount: amount,
                destination: destination,
                txData: txData,
                otherNativeFee: otherNativeFee
            )
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
            let fees = try await tokenFeeLoader.asSolanaTokenFeeLoader().getFee(
                compiledTransaction: data
            )
            try Task.checkCancellation()
            stateSubject.send(.available(fees))
        } catch TokenFeeLoaderError.solanaTokenFeeLoaderNotFound {
            stateSubject.send(.unavailable(.notSupported))
        } catch {
            stateSubject.send(.error(error))
        }
    }
}
