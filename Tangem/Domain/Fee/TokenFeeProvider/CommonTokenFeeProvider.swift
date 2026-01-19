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
    let supportingOptions: TokenFeeProviderSupportingOptions
    let availableTokenBalanceProvider: TokenBalanceProvider
    let tokenFeeLoader: any TokenFeeLoader
    let customFeeProvider: (any CustomFeeProvider)?

    private var tokenFeeProviderInputData: TokenFeeProviderInputData?

    private let stateSubject: CurrentValueSubject<TokenFeeProviderState, Never> = .init(.idle)
    private let selectedFeeOptionSubject: CurrentValueSubject<FeeOption, Never> = .init(.market)

    private var updatingFeeTask: Task<Void, Never>?
    private var customFeeProviderInitialSetupCancellable: AnyCancellable?

    private var tokenHasBalance: Bool {
        availableTokenBalanceProvider.balanceType.value ?? 0 > 0
    }

    init(
        feeTokenItem: TokenItem,
        supportingOptions: TokenFeeProviderSupportingOptions,
        availableTokenBalanceProvider: TokenBalanceProvider,
        tokenFeeLoader: any TokenFeeLoader,
        customFeeProvider: (any CustomFeeProvider)?
    ) {
        self.feeTokenItem = feeTokenItem
        self.supportingOptions = supportingOptions
        self.availableTokenBalanceProvider = availableTokenBalanceProvider
        self.tokenFeeLoader = tokenFeeLoader
        self.customFeeProvider = customFeeProvider

        customFeeProviderInitialSetupCancellable = customFeeProvider?.subscribeToInitialSetup(
            tokenFeeProvider: self
        )

        checkTokenFeeBalance()
    }

    private func checkTokenFeeBalance() {
        if !tokenHasBalance {
            stateSubject.send(.unavailable(.noTokenBalance))
        }
    }
}

// MARK: - TokenFeeProvider

extension CommonTokenFeeProvider: TokenFeeProvider {
    var balanceFeeTokenState: TokenBalanceType { availableTokenBalanceProvider.balanceType }
    var formattedFeeTokenBalance: FormattedTokenBalanceType { availableTokenBalanceProvider.formattedBalanceType }

    var hasMultipleFeeOptions: Bool { tokenFeeLoader.supportingFeeOptions.count > 1 }

    var state: TokenFeeProviderState {
        guard let customFee = customFeeProvider?.customFee else {
            return stateSubject.value
        }

        guard case .available(var fees) = stateSubject.value else {
            return stateSubject.value
        }

        fees[.custom] = customFee
        let filtered = filterBySupportingOptions(fees: fees)

        return .available(filtered)
    }

    var statePublisher: AnyPublisher<TokenFeeProviderState, Never> {
        guard let customFeePublisher = customFeeProvider?.customFeePublisher else {
            return stateSubject.eraseToAnyPublisher()
        }

        return Publishers
            .CombineLatest(stateSubject, customFeePublisher)
            .withWeakCaptureOf(self)
            .map { provider, args in
                let (state, customFee) = args
                guard case .available(var fees) = state else {
                    return state
                }

                fees[.custom] = customFee
                let filtered = provider.filterBySupportingOptions(fees: fees)

                return .available(filtered)
            }
            .eraseToAnyPublisher()
    }

    var selectedTokenFee: TokenFee {
        mapToLoadableTokenFee(
            state: state,
            selectedFeeOption: selectedFeeOptionSubject.value
        )
    }

    var selectedTokenFeePublisher: AnyPublisher<TokenFee, Never> {
        Publishers
            .CombineLatest(statePublisher, selectedFeeOptionSubject)
            .withWeakCaptureOf(self)
            .map { $0.mapToLoadableTokenFee(state: $1.0, selectedFeeOption: $1.1) }
            .eraseToAnyPublisher()
    }

    func select(feeOption: FeeOption) {
        let supportedByLoader = tokenFeeLoader.supportingFeeOptions.contains(feeOption)
        let supportedByRestrictions = switch supportingOptions {
        case .all: true
        case .exactly(let options): options.contains(feeOption)
        }

        if supportedByLoader || supportedByRestrictions {
            selectedFeeOptionSubject.send(feeOption)
        }
    }

    func setup(input: TokenFeeProviderInputData) {
        tokenFeeProviderInputData = input
        updateSupportingState(input: input)
    }

    func updateFees() -> Task<Void, Never> {
        updatingFeeTask?.cancel()

        let task = Task { await updateFees() }
        updatingFeeTask = task

        return task
    }

    private func updateFees() async {
        guard let input = tokenFeeProviderInputData else {
            FeeLogger.error(self, error: "TokenFeeProvider Didn't setup with any input data")
            updateState(state: .unavailable(.inputDataNotSet))
            return
        }

        guard tokenHasBalance else {
            FeeLogger.info(self, "Token has no balance")
            stateSubject.send(.unavailable(.noTokenBalance))
            return
        }

        do {
            if state.loadedFees.isEmpty {
                updateState(state: .loading)
            }

            let loadedFees = try await loadFees(input: input)
            try Task.checkCancellation()

            let fees = mapToFeesDictionary(fees: loadedFees)
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

    func filterBySupportingOptions(fees: [FeeOption: BSDKFee]) -> [FeeOption: BSDKFee] {
        switch supportingOptions {
        case .all:
            return fees
        case .exactly(let options):
            return fees.filter { options.contains($0.key) }
        }
    }
}

// MARK: - FeeSelectorCustomFeeDataProviding

extension CommonTokenFeeProvider: FeeSelectorCustomFeeDataProviding {}

// MARK: - Mapping

private extension CommonTokenFeeProvider {
    func mapToFeesDictionary(fees: [BSDKFee]) -> [FeeOption: BSDKFee] {
        switch fees.count {
        case 1:
            return [.market: fees[0]]
        case 2:
            return [.market: fees[0], .fast: fees[1]]
        case 3:
            return [.slow: fees[0], .market: fees[1], .fast: fees[2]]
        default:
            assertionFailure("Wrong count of fees")
            return [:]
        }
    }

    func mapToLoadableTokenFee(state: TokenFeeProviderState, selectedFeeOption: FeeOption) -> TokenFee {
        let loadableTokenFeeState: LoadingResult<BSDKFee, any Error> = {
            switch state {
            case .idle, .loading:
                return .loading
            case .unavailable:
                return .failure(TokenFee.ErrorType.unsupportedByProvider)
            case .error(let error):
                return .failure(error)
            case .available(let fees):
                if let selectedFeeBySelectedOption = fees[selectedFeeOption] {
                    return .success(selectedFeeBySelectedOption)
                }

                return .failure(TokenFee.ErrorType.feeNotFound)
            }
        }()

        return TokenFee(option: selectedFeeOption, tokenItem: feeTokenItem, value: loadableTokenFeeState)
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
            "input": tokenFeeProviderInputData?.rawCaseValue ?? "",
            "state": state.description,
        ])
    }
}
