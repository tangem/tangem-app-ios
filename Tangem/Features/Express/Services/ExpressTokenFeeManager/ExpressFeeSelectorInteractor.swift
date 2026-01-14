//
//  ExpressFeeSelectorInteractor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemExpress
import Combine

class ExpressFeeSelectorInteractor {
    let sourceTokenFeeManager: ExpressTokenFeeManager
    let expressInteractor: ExpressInteractor

    private var state: ExpressInteractor.State { expressInteractor.getState() }
    private var statePublisher: AnyPublisher<ExpressInteractor.State, Never> {
        expressInteractor.state.filter { !$0.isRefreshRates }.eraseToAnyPublisher()
    }

    init(sourceTokenFeeManager: ExpressTokenFeeManager, expressInteractor: ExpressInteractor) {
        self.sourceTokenFeeManager = sourceTokenFeeManager
        self.expressInteractor = expressInteractor
    }
}

// MARK: - FeeSelectorInteractor

extension ExpressFeeSelectorInteractor: FeeSelectorInteractor {
    var selectedSelectorFee: TokenFee? {
        state.fees.selectedTokenFee()
    }

    var selectedSelectorFeePublisher: AnyPublisher<TokenFee?, Never> {
        statePublisher.map { $0.fees.selectedTokenFee() }.eraseToAnyPublisher()
    }

    var selectorFees: [TokenFee] {
        state.fees.fees
            .filter { $0.option == .market || $0.option == .fast }
    }

    var selectorFeesPublisher: AnyPublisher<[TokenFee], Never> {
        statePublisher
            .map { $0.fees.fees.filter { $0.option == .market || $0.option == .fast } }
            .eraseToAnyPublisher()
    }

    var selectedSelectorTokenFeeProvider: (any TokenFeeProvider)? {
        guard let providerId = state.provider?.id else {
            return nil
        }

        return sourceTokenFeeManager.selectedFeeProvider(providerId: providerId)
    }

    var selectedSelectorTokenFeeProviderPublisher: AnyPublisher<(any TokenFeeProvider)?, Never> {
        statePublisher
            .withWeakCaptureOf(self)
            .map { interactor, state in
                guard let providerId = state.provider?.id else {
                    return nil
                }

                return interactor.sourceTokenFeeManager.selectedFeeProvider(providerId: providerId)
            }
            .eraseToAnyPublisher()
    }

    var selectorTokenFeeProviders: [any TokenFeeProvider] {
        guard let providerId = state.provider?.id else {
            return []
        }

        return sourceTokenFeeManager.feeTokenProviders(providerId: providerId)
    }

    var selectorTokenFeeProvidersPublisher: AnyPublisher<[any TokenFeeProvider], Never> {
        statePublisher
            .withWeakCaptureOf(self)
            .map { interactor, state in
                guard let providerId = state.provider?.id else {
                    return []
                }

                return interactor.sourceTokenFeeManager.feeTokenProviders(providerId: providerId)
            }
            .eraseToAnyPublisher()
    }

    var customFeeProvider: (any CustomFeeProvider)? {
        guard let providerId = state.provider?.id else {
            return nil
        }

        let selectedFeeProvider = sourceTokenFeeManager.selectedFeeProvider(providerId: providerId)
        return (selectedFeeProvider as? FeeSelectorCustomFeeDataProviding)?.customFeeProvider
    }

    func userDidSelectFee(_ fee: TokenFee) {
        expressInteractor.updateFeeOption(option: fee.option)
    }

    func userDidSelect(tokenFeeProvider: any TokenFeeProvider) {
        sourceTokenFeeManager.updateSelectedFeeTokenProviderInAllManagers(tokenFeeProvider: tokenFeeProvider)
    }
}
