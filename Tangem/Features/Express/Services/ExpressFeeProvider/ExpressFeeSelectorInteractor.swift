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
    let sourceTokenFeeManager: ExpressSourceTokenFeeManager
    let expressInteractor: ExpressInteractor

    init(sourceTokenFeeManager: ExpressSourceTokenFeeManager, expressInteractor: ExpressInteractor) {
        self.sourceTokenFeeManager = sourceTokenFeeManager
        self.expressInteractor = expressInteractor
    }
}

extension ExpressFeeSelectorInteractor: FeeSelectorInteractor {
    var selectedSelectorFee: TokenFee? {
        let state = expressInteractor.getState()
        return sourceTokenFeeManager.fees(state: state)[state.fees.selected]
    }

    var selectedSelectorFeePublisher: AnyPublisher<TokenFee?, Never> {
        expressInteractor.state
            .withWeakCaptureOf(self)
            .map { $0.sourceTokenFeeManager.fees(state: $1)[$1.fees.selected] }
            .eraseToAnyPublisher()
    }

    var selectorFees: [TokenFee] { sourceTokenFeeManager.fees(state: expressInteractor.getState()) }
    var selectorFeesPublisher: AnyPublisher<[TokenFee], Never> {
        expressInteractor.state
            .withWeakCaptureOf(self)
            .map { $0.sourceTokenFeeManager.fees(state: $1) }
            .eraseToAnyPublisher()
    }

    var selectedSelectorFeeTokenItem: TokenItem? {
        selectedSelectorFee?.tokenItem
    }

    var selectedSelectorFeeTokenItemPublisher: AnyPublisher<TokenItem?, Never> {
        selectedSelectorFeePublisher
            .map { $0?.tokenItem }
            .eraseToAnyPublisher()
    }

    var selectorFeeTokenItems: [TokenItem] {
        let state = expressInteractor.getState()
        return sourceTokenFeeManager.feeTokenItems(state: state)
    }

    var selectorFeeTokenItemsPublisher: AnyPublisher<[TokenItem], Never> {
        expressInteractor.state
            .withWeakCaptureOf(self)
            .map { $0.sourceTokenFeeManager.feeTokenItems(state: $1) }
            .eraseToAnyPublisher()
    }

    var customFeeProvider: (any CustomFeeProvider)? {
        let state = expressInteractor.getState()
        let selectedFeeProvider = sourceTokenFeeManager.selectedFeeProvider(state: state)

        return (selectedFeeProvider as? FeeSelectorCustomFeeDataProviding)?.customFeeProvider
    }

    func userDidSelectFee(_ fee: TokenFee) {
        expressInteractor.updateFeeOption(option: fee.option)
    }

    func userDidSelectTokenItem(_ tokenItem: TokenItem) {
        let state = expressInteractor.getState()
        let tokenFeeManager = sourceTokenFeeManager.tokenFeeManager(state: state)
        tokenFeeManager?.updateSelectedFeeProvider(tokenItem: tokenItem)
    }
}
