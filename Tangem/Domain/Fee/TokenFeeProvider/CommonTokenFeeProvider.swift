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

let FeeLogger = AppLogger.tag("TokenFeeProvider")

final class CommonTokenFeeProvider {
    let feeTokenItem: TokenItem
    let availableTokenBalanceProvider: TokenBalanceProvider
    let tokenFeeLoader: any TokenFeeLoader
    let customFeeProvider: (any CustomFeeProvider)?

    private var tokenFeeProviderInputData: TokenFeeProviderInputData? {
        didSet {
            if oldValue != tokenFeeProviderInputData {
                updateSupportingState(input: tokenFeeProviderInputData)
            }
        }
    }

    private let stateSubject: CurrentValueSubject<TokenFeeProviderState, Never> = .init(.idle)
    private var customFeeProviderInitialSetupCancellable: AnyCancellable?

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

    func setup(input: TokenFeeProviderInputData) {
        tokenFeeProviderInputData = input
        updateSupportingState(input: input)
    }

    func updateFees() async {
        guard let input = tokenFeeProviderInputData else {
            FeeLogger.error(self, error: "TokenFeeProvider Didn't setup with any input data")
            updateState(state: .unavailable(.inputDataNotSet))
            return
        }

        do {
            updateState(state: .loading)
            let fees = try await loadFees(input: input)

            try Task.checkCancellation()
            updateState(state: .available(fees))

        } catch TokenFeeLoaderError.tokenFeeLoaderNotFound {
            updateState(state: .unavailable(.notSupported))
        } catch is CancellationError {
            updateState(state: .idle)
        } catch {
            updateState(state: .error(error))
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

// MARK: - Private

private extension CommonTokenFeeProvider {
    func updateSupportingState(input: TokenFeeProviderInputData?) {
        switch input {
        case .none:
            updateState(state: .unavailable(.inputDataNotSet))
        case .common, .cex:
            // Always available. Do nothing
            break
        case .dex(.ethereumEstimate) where tokenFeeLoader is EthereumTokenFeeLoader,
             .dex(.ethereum) where tokenFeeLoader is EthereumTokenFeeLoader:
            // Is available. Do nothing
            break
        case .dex(.solana) where tokenFeeLoader is SolanaTokenFeeLoader:
            // Is available. Do nothing
            break
        case .dex:
            // DEX but tokenFeeLoader is not (EthereumTokenFeeLoader or SolanaTokenFeeLoader)
            updateState(state: .unavailable(.notSupported))
        }
    }

    func updateState(state: TokenFeeProviderState) {
        switch state {
        case .idle, .available, .loading:
            FeeLogger.info(self, "Will update state to \(state)")
        case .unavailable:
            FeeLogger.warning(self, "Will update state to \(state)")
        case .error(let error):
            FeeLogger.error(self, "Will update state", error: error)
        }

        stateSubject.send(state)
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
