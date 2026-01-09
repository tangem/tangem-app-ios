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

    private let tokenFeeManager: TokenFeeManager

    init(
        input: any FeeSelectorInteractorInput,
        output: any FeeSelectorOutput,
        tokenFeeManager: TokenFeeManager,
    ) {
        self.input = input
        self.output = output
        self.tokenFeeManager = tokenFeeManager
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
    var selectorFees: [TokenFee] { tokenFeeManager.fees }
    var selectorFeesPublisher: AnyPublisher<[TokenFee], Never> { tokenFeeManager.feesPublisher }
}

// MARK: - FeeSelectorTokensDataProvider

extension CommonFeeSelectorInteractor: FeeSelectorTokensDataProvider {
    var selectedSelectorFeeTokenItem: TokenItem? { selectedSelectorFee?.tokenItem }
    var selectedSelectorFeeTokenItemPublisher: AnyPublisher<TokenItem?, Never> { selectedSelectorFeePublisher.map { $0?.tokenItem }.eraseToAnyPublisher() }

    var selectorFeeTokenItems: [TokenItem] { tokenFeeManager.selectorFeeTokenItems }
    var selectorFeeTokenItemsPublisher: AnyPublisher<[TokenItem], Never> { tokenFeeManager.selectorFeeTokenItemsPublisher }
}

// MARK: - Private

private extension CommonFeeSelectorInteractor {}
