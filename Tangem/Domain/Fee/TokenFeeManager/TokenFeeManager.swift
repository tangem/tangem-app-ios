//
//  TokenFeeManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

final class TokenFeeManager {
    private let feeProviders: [any TokenFeeProvider]

    private let selectedProviderSubject: CurrentValueSubject<any TokenFeeProvider, Never>
    private let selectedFeeOptionSubject: CurrentValueSubject<FeeOption, Never>

    private var updatingFeeTask: Task<Void, Never>?

    init(
        feeProviders: [any TokenFeeProvider],
        initialSelectedProvider: any TokenFeeProvider,
        selectedFeeOption: FeeOption = .market
    ) {
        self.feeProviders = feeProviders

        selectedProviderSubject = .init(initialSelectedProvider)
        selectedFeeOptionSubject = .init(selectedFeeOption)
    }
}

// MARK: - Public

extension TokenFeeManager {
    var selectedLoadableFee: LoadableTokenFee {
        mapToLoadableTokenFee(state: selectedFeeProvider.state, option: selectedFeeOptionSubject.value)
    }

    var selectedLoadableFeePublisher: AnyPublisher<LoadableTokenFee, Never> {
        Publishers
            .CombineLatest(selectedFeeProvider.statePublisher, selectedFeeOptionSubject)
            .withWeakCaptureOf(self)
            .map { $0.mapToLoadableTokenFee(state: $1.0, option: $1.1) }
            .eraseToAnyPublisher()
    }

    var hasMultipleFeeOptions: AnyPublisher<Bool, Never> {
        Publishers.CombineLatest(
            selectedFeeProviderFeesPublisher.map { $0.hasMultipleFeeOptions },
            supportedFeeTokenProvidersPublisher.map { $0.count > 1 }.eraseToAnyPublisher(),
        )
        .map { $0 || $1 }
        .removeDuplicates()
        .eraseToAnyPublisher()
    }

    var selectedFeeOption: FeeOption {
        selectedFeeOptionSubject.value
    }

    var selectedFeeProvider: any TokenFeeProvider {
        selectedProviderSubject.value
    }

    var selectedFeeProviderPublisher: AnyPublisher<any TokenFeeProvider, Never> {
        selectedProviderSubject.eraseToAnyPublisher()
    }

    var selectedFeeProviderFees: [LoadableTokenFee] { selectedFeeProvider.fees }
    var selectedFeeProviderFeesPublisher: AnyPublisher<[LoadableTokenFee], Never> {
        selectedFeeProviderPublisher.flatMapLatest(\.feesPublisher).eraseToAnyPublisher()
    }

    var supportedFeeTokenProviders: [any TokenFeeProvider] {
        feeProviders.filter { $0.state.isSupported }
    }

    var supportedFeeTokenProvidersPublisher: AnyPublisher<[any TokenFeeProvider], Never> {
        .just(output: feeProviders)
    }

    func updateSelectedFeeProvider(tokenFeeProvider: any TokenFeeProvider) {
        selectedProviderSubject.send(tokenFeeProvider)
    }

    func updateSelectedFeeOption(feeOption: FeeOption) {
        selectedFeeOptionSubject.send(feeOption)
    }

    func setupFeeProviders(input: TokenFeeProviderInputData) {
        feeProviders.forEach { $0.setup(input: input) }
    }

    func updateSelectedFeeProviderFees() {
        updatingFeeTask?.cancel()
        updatingFeeTask = Task {
            await selectedFeeProvider.updateFees()
        }
    }

    private func mapToLoadableTokenFee(state: TokenFeeProviderState, option: FeeOption) -> LoadableTokenFee {
        let loadableTokenFeeState: LoadingResult<BSDKFee, any Error> = {
            switch state {
            case .idle, .loading: return .loading
            case .unavailable: return .failure(LoadableTokenFee.ErrorType.unsupportedByProvider)
            case .error(let error): return .failure(error)
            case .available(let fees):
                let fees = TokenFeeConverter.mapToFeesDictionary(fees: fees)
                let selectedFeeOption = selectedFeeOptionSubject.value

                if let selectedFeeBySelectedOption = fees[selectedFeeOption] {
                    return .success(selectedFeeBySelectedOption)
                }

                if let selectedFeeByMarketOption = fees[.market] {
                    return .success(selectedFeeByMarketOption)
                }

                return .failure(LoadableTokenFee.ErrorType.feeNotFound)
            }
        }()

        return LoadableTokenFee(
            option: selectedFeeOptionSubject.value,
            tokenItem: selectedFeeProvider.feeTokenItem,
            value: loadableTokenFeeState
        )
    }
}

// MARK: - FeeSelectorInteractor

extension TokenFeeManager: FeeSelectorInteractor {
    var selectedSelectorFee: LoadableTokenFee? { selectedLoadableFee }
    var selectedSelectorFeePublisher: AnyPublisher<LoadableTokenFee?, Never> {
        selectedLoadableFeePublisher.eraseToOptional().eraseToAnyPublisher()
    }

    var selectorFees: [LoadableTokenFee] { selectedFeeProviderFees }
    var selectorFeesPublisher: AnyPublisher<[LoadableTokenFee], Never> {
        selectedFeeProviderFeesPublisher
    }

    var selectedSelectorTokenFeeProvider: (any TokenFeeProvider)? { selectedFeeProvider }
    var selectedSelectorTokenFeeProviderPublisher: AnyPublisher<(any TokenFeeProvider)?, Never> {
        selectedFeeProviderPublisher.eraseToOptional().eraseToAnyPublisher()
    }

    var selectorTokenFeeProviders: [any TokenFeeProvider] { supportedFeeTokenProviders }
    var selectorTokenFeeProvidersPublisher: AnyPublisher<[any TokenFeeProvider], Never> {
        supportedFeeTokenProvidersPublisher
    }

    var customFeeProvider: (any CustomFeeProvider)? {
        (selectedFeeProvider as? FeeSelectorCustomFeeDataProviding)?.customFeeProvider
    }

    func userDidSelectFee(_ fee: LoadableTokenFee) {
        selectedFeeOptionSubject.send(fee.option)
    }

    func userDidSelect(tokenFeeProvider: any TokenFeeProvider) {
        updateSelectedFeeProvider(tokenFeeProvider: tokenFeeProvider)
        updateSelectedFeeProviderFees()
    }
}
