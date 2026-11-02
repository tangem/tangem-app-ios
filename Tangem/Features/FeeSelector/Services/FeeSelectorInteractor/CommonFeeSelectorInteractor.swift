//
//  CommonFeeSelectorInteractor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

final class CommonFeeSelectorInteractor {
    private let tokenFeeProvidersSubject: CurrentValueSubject<[any TokenFeeProvider], Never>
    private let selectedTokenFeeProviderSubject: CurrentValueSubject<any TokenFeeProvider, Never>
    private let selectedTokenFeeOptionSubject: CurrentValueSubject<[TokenFeeProviderID: FeeOption], Never>

    private weak var output: FeeSelectorOutput?

    init(
        tokenFeeProviders: [any TokenFeeProvider],
        selectedTokenFeeProvider: any TokenFeeProvider,
        output: FeeSelectorOutput
    ) {
        tokenFeeProvidersSubject = .init(tokenFeeProviders)
        selectedTokenFeeProviderSubject = .init(selectedTokenFeeProvider)
        selectedTokenFeeOptionSubject = .init([
            selectedTokenFeeProvider.id: selectedTokenFeeProvider.selectedTokenFee.option,
        ])

        self.output = output
    }
}

// MARK: - FeeSelectorInteractor

extension CommonFeeSelectorInteractor: FeeSelectorInteractor {
    var state: FeeSelectorInteractorState {
        supportedTokenFeeProviders.count > 1 ? .multiple : .single
    }

    func userDidSelect(feeOption: FeeOption) {
        selectedTokenFeeOptionSubject.value[selectedTokenFeeProvider.id] = feeOption
    }

    func userDidSelect(feeProviderID: TokenFeeProviderID) {
        assert(state == .multiple, "Supposed to be called only in .multiple state")

        guard let tokenFeeProvider = supportedTokenFeeProviders[feeProviderID] else {
            return
        }

        selectedTokenFeeProviderSubject.send(tokenFeeProvider)
        tokenFeeProvider.updateFees()
    }

    func completeSelection() {
        output?.userDidFinishSelection(
            feeProviderID: selectedTokenFeeProvider.id,
            feeOption: selectedTokenFeeOption
        )
    }
}

// MARK: - FeeSelectorFeesDataProvider

extension CommonFeeSelectorInteractor: FeeSelectorFeesDataProvider {
    var selectedTokenFeeOption: FeeOption {
        selectedTokenFeeOptionSubject.value[selectedTokenFeeProvider.id, default: .market]
    }

    var feeCoveragePublisher: AnyPublisher<FeeCoverage, Never> {
        Publishers
            .CombineLatest(
                selectedTokenFeePublisher,
                selectedTokenFeeProviderPublisher.flatMapLatest { $0.balanceTypePublisher },
            )
            .withWeakCaptureOf(self)
            .map { provider, output in
                let (tokenFee, balance) = output
                switch tokenFee.value {
                case .success(let fee):
                    let required = fee.amount.value
                    let availableBalance = balance.value ?? 0
                    let difference = availableBalance - required
                    return difference >= 0 ? .covered(feeValue: required) : .uncovered(missingAmount: -difference)
                case .failure, .loading:
                    return .undefined
                }
            }
            .eraseToAnyPublisher()
    }

    var selectedTokenFeeOptionPublisher: AnyPublisher<FeeOption, Never> {
        Publishers
            .CombineLatest(selectedTokenFeeOptionSubject, selectedTokenFeeProviderPublisher)
            .map { $0[$1.id, default: .market] }
            .eraseToAnyPublisher()
    }

    var selectorFees: [TokenFee] {
        selectedTokenFeeProvider.fees
    }

    var selectorFeesPublisher: AnyPublisher<[TokenFee], Never> {
        selectedTokenFeeProviderPublisher
            .flatMapLatest { $0.feesPublisher }
            .eraseToAnyPublisher()
    }
}

// MARK: - FeeSelectorTokensDataProvider

extension CommonFeeSelectorInteractor: FeeSelectorTokensDataProvider {
    var selectedTokenFeeProvider: any TokenFeeProvider {
        selectedTokenFeeProviderSubject.value
    }

    var selectedTokenFeeProviderPublisher: AnyPublisher<any TokenFeeProvider, Never> {
        selectedTokenFeeProviderSubject.eraseToAnyPublisher()
    }

    var supportedTokenFeeProviders: [any TokenFeeProvider] {
        tokenFeeProvidersSubject.value.filter { $0.state.isSupported }
    }

    var supportedTokenFeeProvidersPublisher: AnyPublisher<[any TokenFeeProvider], Never> {
        tokenFeeProvidersSubject.map { $0.filter { $0.state.isSupported } }.eraseToAnyPublisher()
    }
}

// MARK: - FeeSelectorCustomFeeDataProviding

extension CommonFeeSelectorInteractor: FeeSelectorCustomFeeDataProviding {
    var customFeeProvider: (any CustomFeeProvider)? {
        (selectedTokenFeeProvider as? FeeSelectorCustomFeeDataProviding)?.customFeeProvider
    }
}
