//
//  CommonSwapFeeProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class CommonSwapFeeProvider {
    private let expressInteractor: ExpressInteractor

    private var expressFeeSelectorInteractor: ExpressFeeSelectorInteractor? {
        guard let sourceTokenFeeManager = expressInteractor.getSource().value?.expressTokenFeeManager else {
            return nil
        }

        return ExpressFeeSelectorInteractor(
            sourceTokenFeeManager: sourceTokenFeeManager,
            expressInteractor: expressInteractor
        )
    }

    private var expressFeeSelectorInteractorPublisher: AnyPublisher<ExpressFeeSelectorInteractor, Never> {
        expressInteractor.swappingPair
            .compactMap { $0.sender.value }
            .withWeakCaptureOf(self)
            .map { provider, sender in
                ExpressFeeSelectorInteractor(
                    sourceTokenFeeManager: sender.expressTokenFeeManager,
                    expressInteractor: provider.expressInteractor
                )
            }
            .eraseToAnyPublisher()
    }

    init(expressInteractor: ExpressInteractor) {
        self.expressInteractor = expressInteractor
    }
}

// MARK: - SendFeeProvider

extension CommonSwapFeeProvider: SendFeeProvider {
    var fees: [TokenFee] { selectorFees }
    var feesPublisher: AnyPublisher<[TokenFee], Never> { selectorFeesPublisher }
    var feesHasMultipleFeeOptions: AnyPublisher<Bool, Never> {
        expressFeeSelectorInteractorPublisher
            .flatMapLatest { $0.selectorHasMultipleFeeOptions }
            .eraseToAnyPublisher()
    }

    func updateFees() {
        expressInteractor.refresh(type: .fee)
    }
}

// MARK: - FeeSelectorInteractor

extension CommonSwapFeeProvider: FeeSelectorInteractor {
    var selectedSelectorFee: TokenFee? { expressFeeSelectorInteractor?.selectedSelectorFee }
    var selectedSelectorFeePublisher: AnyPublisher<TokenFee?, Never> {
        expressFeeSelectorInteractorPublisher
            .flatMapLatest { $0.selectedSelectorFeePublisher }
            .eraseToAnyPublisher()
    }

    var selectorFees: [TokenFee] { expressFeeSelectorInteractor?.selectorFees ?? [] }
    var selectorFeesPublisher: AnyPublisher<[TokenFee], Never> {
        expressFeeSelectorInteractorPublisher
            .flatMapLatest { $0.selectorFeesPublisher }
            .eraseToAnyPublisher()
    }

    var selectedSelectorFeeTokenItem: TokenItem? { expressFeeSelectorInteractor?.selectedSelectorFeeTokenItem }
    var selectedSelectorFeeTokenItemPublisher: AnyPublisher<TokenItem?, Never> {
        expressFeeSelectorInteractorPublisher
            .flatMapLatest { $0.selectedSelectorFeeTokenItemPublisher }
            .eraseToAnyPublisher()
    }

    var selectorFeeTokenItems: [TokenItem] { expressFeeSelectorInteractor?.selectorFeeTokenItems ?? [] }
    var selectorFeeTokenItemsPublisher: AnyPublisher<[TokenItem], Never> {
        expressFeeSelectorInteractorPublisher
            .flatMapLatest { $0.selectorFeeTokenItemsPublisher }
            .eraseToAnyPublisher()
    }

    var customFeeProvider: (any CustomFeeProvider)? {
        expressFeeSelectorInteractor?.customFeeProvider
    }

    func userDidSelectFee(_ fee: TokenFee) {
        expressFeeSelectorInteractor?.userDidSelectFee(fee)
    }

    func userDidSelectTokenItem(_ tokenItem: TokenItem) {
        expressFeeSelectorInteractor?.userDidSelectTokenItem(tokenItem)
    }
}
