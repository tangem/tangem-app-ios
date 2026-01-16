//
//  CommonTokenFeeProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import TangemMacro

class CommonTokenFeeProvider {
    let feeTokenItem: TokenItem
    let availableTokenBalanceProvider: TokenBalanceProvider
    let tokenFeeLoader: any TokenFeeLoader
    let customFeeProvider: (any CustomFeeProvider)?

    var tokenFeeProviderInputData: TokenFeeProviderInputData?
    let stateSubject: CurrentValueSubject<TokenFeeProviderState, Never> = .init(.idle)

    private var customFeeProviderInitialSetupCancellable: AnyCancellable?

    private var tokenHasNoBalance: Bool {
        switch availableTokenBalanceProvider.balanceType.value {
        case .none:
            true
        case .some(let balance) where balance.isZero:
            true
        case .some:
            false
        }
    }

    init(
        feeTokenItem: TokenItem,
        availableTokenBalanceProvider: TokenBalanceProvider,
        tokenFeeLoader: any TokenFeeLoader,
        customFeeProvider: (any CustomFeeProvider)?
    ) {
        self.feeTokenItem = feeTokenItem
        self.availableTokenBalanceProvider = availableTokenBalanceProvider
        self.tokenFeeLoader = tokenFeeLoader
        self.customFeeProvider = customFeeProvider

        customFeeProviderInitialSetupCancellable = customFeeProvider?.subscribeToInitialSetup(
            tokenFeeProvider: self
        )

        checkTokenFeeBalance()
    }

    private func checkTokenFeeBalance() {
        if tokenHasNoBalance {
            stateSubject.send(.unavailable(.noTokenBalance))
        }
    }
}

// MARK: - TokenFeeProvider

extension CommonTokenFeeProvider: TokenFeeProvider {
    var balanceState: FormattedTokenBalanceType { availableTokenBalanceProvider.formattedBalanceType }

    var state: TokenFeeProviderState { stateSubject.value }
    var statePublisher: AnyPublisher<TokenFeeProviderState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

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

    func updateSupportingState(input: TokenFeeProviderInputData) {
        let isAvailable = switch input {
        // Always available
        case .common, .cex: true
        case .dex(.ethereumEstimate), .dex(.ethereum): tokenFeeLoader is EthereumTokenFeeLoader
        case .dex(.solana): tokenFeeLoader is SolanaTokenFeeLoader
        }

        if !isAvailable {
            stateSubject.send(.unavailable(.notSupported))
        }
    }

    func setup(input: TokenFeeProviderInputData) {
        tokenFeeProviderInputData = input
    }

    func updateFees() async {
        guard let input = tokenFeeProviderInputData else {
            AppLogger.error(self, error: "TokenFeeProvider Didn't setup with any input data")
            stateSubject.send(.unavailable(.inputDataNotSet))
            return
        }

        do {
            stateSubject.send(.loading)
            AppLogger.info(self, "Start loading")

            let fees = try await loadFees(input: input)
            try Task.checkCancellation()

            if tokenHasNoBalance {
                stateSubject.send(.unavailable(.noTokenBalance))
                AppLogger.info(self, "Token has no balance")
                return
            }

            stateSubject.send(.available(fees))
            AppLogger.info(self, "Did load fees")

        } catch TokenFeeLoaderError.tokenFeeLoaderNotFound {
            stateSubject.send(.unavailable(.notSupported))
            AppLogger.warning(self, "Catch TokenFeeLoaderNotFound")

        } catch is CancellationError {
            stateSubject.send(.idle)
            AppLogger.warning(self, "Catch CancellationError")
        } catch {
            AppLogger.error(self, error: error)
            stateSubject.send(.error(error))
        }
    }

    private func loadFees(input: TokenFeeProviderInputData) async throws -> [BSDKFee] {
        switch input {
        case .common(let amount, let destination):
            return try await updateFees(amount: amount, destination: destination)

        case .cex(let amount):
            return try await updateFees(amount: amount)

        case .dex(.ethereumEstimate(let estimatedGasLimit, let otherNativeFee)):
            return try await updateFees(estimatedGasLimit: estimatedGasLimit, otherNativeFee: otherNativeFee)

        case .dex(.ethereum(let amount, let destination, let txData, let otherNativeFee)):
            return try await updateFees(amount: amount, destination: destination, txData: txData, otherNativeFee: otherNativeFee)

        case .dex(.solana(let data)):
            return try await updateFees(compiledTransaction: data)
        }
    }
}

// MARK: - FeeSelectorCustomFeeDataProviding

extension CommonTokenFeeProvider: FeeSelectorCustomFeeDataProviding {}

// MARK: - Mapping

private extension CommonTokenFeeProvider {
    func mapToTokenFees(state: TokenFeeProviderState) -> [TokenFee] {
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

// MARK: - Updating

private extension CommonTokenFeeProvider {
    // MARK: - Common

    func updateFees(amount: Decimal, destination: String) async throws -> [BSDKFee] {
        let fees = try await tokenFeeLoader.getFee(amount: amount, destination: destination)
        try Task.checkCancellation()
        return fees
    }

    func updateFees(amount: Decimal) async throws -> [BSDKFee] {
        let fees = try await tokenFeeLoader.estimatedFee(amount: amount)
        try Task.checkCancellation()
        return fees
    }

    // MARK: - Ethereum

    private func updateFees(estimatedGasLimit: Int, otherNativeFee: Decimal?) async throws -> [BSDKFee] {
        let fee = try await tokenFeeLoader.asEthereumTokenFeeLoader().estimatedFee(
            estimatedGasLimit: estimatedGasLimit,
            otherNativeFee: otherNativeFee
        )
        try Task.checkCancellation()
        return [fee]
    }

    private func updateFees(amount: BSDKAmount, destination: String, txData: Data, otherNativeFee: Decimal?) async throws -> [BSDKFee] {
        let fees = try await tokenFeeLoader.asEthereumTokenFeeLoader().getFee(
            amount: amount,
            destination: destination,
            txData: txData,
            otherNativeFee: otherNativeFee
        )
        try Task.checkCancellation()
        return fees
    }

    // MARK: - Solana

    func updateFees(compiledTransaction data: Data) async throws -> [BSDKFee] {
        let fees = try await tokenFeeLoader.asSolanaTokenFeeLoader().getFee(compiledTransaction: data)
        try Task.checkCancellation()
        return fees
    }
}

// MARK: - CustomStringConvertible

extension CommonTokenFeeProvider: CustomStringConvertible {
    var description: String {
        objectDescription(self, userInfo: [
            "feeTokenItem": feeTokenItem.name,
            "feeTokenItemBlockchain": feeTokenItem.blockchain.displayName,
            "state": state.description,
        ])
    }
}
