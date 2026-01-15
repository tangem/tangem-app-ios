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

    init(expressInteractor: ExpressInteractor) {
        self.expressInteractor = expressInteractor
    }
}

// MARK: - SendFeeUpdater

extension CommonSwapFeeProvider: SendFeeUpdater {
    func updateFees() {
        expressInteractor.refresh(type: .fee)
    }
}

// MARK: - FeeSelectorInteractor (ExpressInteractor Proxy)

extension CommonSwapFeeProvider: FeeSelectorInteractor {
    var selectedSelectorFee: LoadableTokenFee? { expressInteractor.selectedSelectorFee }
    var selectedSelectorFeePublisher: AnyPublisher<LoadableTokenFee?, Never> {
        expressInteractor.selectedSelectorFeePublisher
    }

    var selectorFees: [LoadableTokenFee] { expressInteractor.selectorFees }
    var selectorFeesPublisher: AnyPublisher<[LoadableTokenFee], Never> {
        expressInteractor.selectorFeesPublisher
    }

    var selectedSelectorTokenFeeProvider: (any TokenFeeProvider)? {
        expressInteractor.selectedSelectorTokenFeeProvider
    }

    var selectedSelectorTokenFeeProviderPublisher: AnyPublisher<(any TokenFeeProvider)?, Never> {
        expressInteractor.selectedSelectorTokenFeeProviderPublisher
    }

    var selectorTokenFeeProviders: [any TokenFeeProvider] {
        expressInteractor.selectorTokenFeeProviders
    }

    var selectorTokenFeeProvidersPublisher: AnyPublisher<[any TokenFeeProvider], Never> {
        expressInteractor.selectorTokenFeeProvidersPublisher
    }

    var customFeeProvider: (any CustomFeeProvider)? {
        expressInteractor.customFeeProvider
    }

    func userDidSelectFee(_ fee: LoadableTokenFee) {
        expressInteractor.userDidSelectFee(fee)
    }

    func userDidSelect(tokenFeeProvider: any TokenFeeProvider) {
        expressInteractor.userDidSelect(tokenFeeProvider: tokenFeeProvider)
    }
}
