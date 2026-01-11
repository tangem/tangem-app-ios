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

// MARK: - FeeSelectorInteractor

extension ExpressFeeSelectorInteractor: FeeSelectorInteractor {
    var selectedSelectorFee: TokenFee? {
        expressInteractor.getState().fees.selectedTokenFee()
    }

    var selectedSelectorFeePublisher: AnyPublisher<TokenFee?, Never> {
        expressInteractor.state.map { $0.fees.selectedTokenFee() }.eraseToAnyPublisher()
    }

    var selectorFees: [TokenFee] {
        expressInteractor.getState().fees.fees
    }

    var selectorFeesPublisher: AnyPublisher<[TokenFee], Never> {
        expressInteractor.state.map { $0.fees.fees }.eraseToAnyPublisher()
    }

    var selectedSelectorFeeTokenItem: TokenItem? {
        expressInteractor.getState().fees.selectedTokenFee()?.tokenItem
    }

    var selectedSelectorFeeTokenItemPublisher: AnyPublisher<TokenItem?, Never> {
        expressInteractor.state.map { $0.fees.selectedTokenFee()?.tokenItem }.eraseToAnyPublisher()
    }

    var selectorFeeTokenItems: [TokenItem] {
        guard let providerId = expressInteractor.getState().provider?.id else {
            return []
        }

        return sourceTokenFeeManager.feeTokenItems(providerId: providerId)
    }

    var selectorFeeTokenItemsPublisher: AnyPublisher<[TokenItem], Never> {
        expressInteractor.state
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
        guard let providerId = expressInteractor.getState().provider?.id else {
            return nil
        }

        let selectedFeeProvider = sourceTokenFeeManager.selectedFeeProvider(providerId: providerId)
        return (selectedFeeProvider as? FeeSelectorCustomFeeDataProviding)?.customFeeProvider
    }

    func userDidSelectFee(_ fee: TokenFee) {
        expressInteractor.updateFeeOption(option: fee.option)
    }

    func userDidSelectTokenItem(_ tokenItem: TokenItem) {
        guard let providerId = expressInteractor.getState().provider?.id else {
            return
        }

        let tokenFeeManager = sourceTokenFeeManager.tokenFeeManager(providerId: providerId)
        tokenFeeManager?.updateSelectedFeeProvider(tokenItem: tokenItem)
    }
}
