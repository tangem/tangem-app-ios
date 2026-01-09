//
//  CommonFeeSelectorInteractor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

final class CommonFeeSelectorInteractor {
    private weak var input: (any FeeSelectorInteractorInput)?
    private weak var output: (any FeeSelectorOutput)?
    private weak var dataProvider: (any FeeSelectorInteractorDataProvider)?

    init(
        input: any FeeSelectorInteractorInput,
        output: any FeeSelectorOutput,
        dataProvider: any FeeSelectorInteractorDataProvider,
    ) {
        self.input = input
        self.output = output
        self.dataProvider = dataProvider
    }
}

// MARK: - FeeSelectorInteractor

extension CommonFeeSelectorInteractor: FeeSelectorInteractor {}

// MARK: - FeeSelectorFeesDataProvider

extension CommonFeeSelectorInteractor: FeeSelectorFeesDataProvider {
    var selectedSelectorFee: TokenFee? { input?.selectedFee }
    var selectedSelectorFeePublisher: AnyPublisher<TokenFee?, Never> {
        input?.selectedFeePublisher.eraseToOptional().eraseToAnyPublisher() ?? .just(output: .none)
    }

    var selectorFees: [TokenFee] { dataProvider?.selectorFees ?? [] }
    var selectorFeesPublisher: AnyPublisher<[TokenFee], Never> {
        dataProvider?.selectorFeesPublisher ?? .just(output: [])
    }
}

// MARK: - FeeSelectorTokensDataProvider

extension CommonFeeSelectorInteractor: FeeSelectorTokensDataProvider {
    var selectedSelectorFeeTokenItem: TokenItem? { input?.selectedFee.tokenItem }
    var selectedSelectorFeeTokenItemPublisher: AnyPublisher<TokenItem?, Never> {
        input?.selectedFeePublisher.map { $0.tokenItem }.eraseToOptional().eraseToAnyPublisher() ?? .just(output: .none)
    }

    var selectorFeeTokenItems: [TokenItem] { dataProvider?.selectorFeeTokenItems ?? [] }
    var selectorFeeTokenItemsPublisher: AnyPublisher<[TokenItem], Never> {
        dataProvider?.selectorFeeTokenItemsPublisher ?? .just(output: [])
    }
}

// MARK: - Private

private extension CommonFeeSelectorInteractor {}
