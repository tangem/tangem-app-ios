//
//  FeeSelectorInteractor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

protocol FeeSelectorInteractorInput: AnyObject {
    var selectedFee: LoadableTokenFee { get }
    var selectedFeePublisher: AnyPublisher<LoadableTokenFee, Never> { get }
}

protocol FeeSelectorInteractorOutput: AnyObject {
    func userDidSelect(tokenFeeProvider: any TokenFeeProvider)
    func userDidSelectFee(_ fee: LoadableTokenFee)
}

protocol FeeSelectorInteractor: FeeSelectorTokensDataProvider, FeeSelectorFeesDataProvider, FeeSelectorCustomFeeDataProviding {
    func userDidSelect(tokenFeeProvider: any TokenFeeProvider)
    func userDidSelectFee(_ fee: LoadableTokenFee)
}

extension FeeSelectorInteractor {
    var hasMultipleFeeProviders: Bool { selectorTokenFeeProviders.count > 1 }
    var hasMultipleFeeProvidersPublisher: AnyPublisher<Bool, Never> {
        selectorTokenFeeProvidersPublisher.map { $0.count > 1 }.eraseToAnyPublisher()
    }

    var selectorHasMultipleFeeOptions: AnyPublisher<Bool, Never> {
        Publishers.CombineLatest(
            selectorFeesPublisher.map { $0.hasMultipleFeeOptions },
            hasMultipleFeeProvidersPublisher,
        )
        .map { $0 || $1 }
        .removeDuplicates()
        .eraseToAnyPublisher()
    }
}

final class CommonFeeSelectorInteractor {
    let tokenFeeManager: TokenFeeManager
    let output: FeeSelectorInteractorOutput

    init(tokenFeeManager: TokenFeeManager, output: FeeSelectorInteractorOutput) {
        self.tokenFeeManager = tokenFeeManager
        self.output = output
    }
}

// MARK: - FeeSelectorInteractor

extension CommonFeeSelectorInteractor: FeeSelectorInteractor {
    var selectedSelectorFee: LoadableTokenFee? { tokenFeeManager.selectedLoadableFee }
    var selectedSelectorFeePublisher: AnyPublisher<LoadableTokenFee?, Never> {
        tokenFeeManager.selectedLoadableFeePublisher.eraseToOptional().eraseToAnyPublisher()
    }

    var selectorFees: [LoadableTokenFee] { tokenFeeManager.selectedFeeProviderFees }
    var selectorFeesPublisher: AnyPublisher<[LoadableTokenFee], Never> {
        tokenFeeManager.selectedFeeProviderFeesPublisher
    }

    var selectedSelectorTokenFeeProvider: (any TokenFeeProvider)? { tokenFeeManager.selectedFeeProvider }
    var selectedSelectorTokenFeeProviderPublisher: AnyPublisher<(any TokenFeeProvider)?, Never> {
        tokenFeeManager.selectedFeeProviderPublisher.eraseToOptional().eraseToAnyPublisher()
    }

    var selectorTokenFeeProviders: [any TokenFeeProvider] { tokenFeeManager.supportedFeeTokenProviders }
    var selectorTokenFeeProvidersPublisher: AnyPublisher<[any TokenFeeProvider], Never> {
        tokenFeeManager.supportedFeeTokenProvidersPublisher
    }

    var customFeeProvider: (any CustomFeeProvider)? {
        (tokenFeeManager.selectedFeeProvider as? FeeSelectorCustomFeeDataProviding)?.customFeeProvider
    }

    func userDidSelectFee(_ fee: LoadableTokenFee) {
        // output?.feeDidChanged(fee: fee)
    }

    func userDidSelect(tokenFeeProvider: any TokenFeeProvider) {
        tokenFeeManager.updateSelectedFeeProvider(tokenFeeProvider: tokenFeeProvider)
        tokenFeeManager.updateSelectedFeeProviderFees()
    }
}
