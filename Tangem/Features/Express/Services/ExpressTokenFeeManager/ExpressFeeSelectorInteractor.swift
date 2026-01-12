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

    var selectedSelectorFeeTokenItem: TokenItem? {
        state.fees.selectedTokenFee()?.tokenItem
    }

    var selectedSelectorFeeTokenItemPublisher: AnyPublisher<TokenItem?, Never> {
        statePublisher.map { $0.fees.selectedTokenFee()?.tokenItem }.eraseToAnyPublisher()
    }

    var selectorFeeTokenItems: [TokenItem] {
        guard let providerId = state.provider?.id else {
            return []
        }

        return sourceTokenFeeManager.feeTokenItems(providerId: providerId)
    }

    var selectorFeeTokenItemsPublisher: AnyPublisher<[TokenItem], Never> {
        statePublisher
            .withWeakCaptureOf(self)
            .map { interactor, state in
                guard let providerId = state.provider?.id else {
                    return []
                }

                return interactor.sourceTokenFeeManager.feeTokenItems(providerId: providerId)
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

    func userDidSelectTokenItem(_ tokenItem: TokenItem) {
        sourceTokenFeeManager.updateSelectedFeeTokenItem(tokenItem: tokenItem)
    }
}
