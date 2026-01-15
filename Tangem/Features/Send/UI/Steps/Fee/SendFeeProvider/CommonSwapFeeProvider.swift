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

// MARK: - SendFeeProvider

extension CommonSwapFeeProvider: SendFeeProvider {
    var fees: [TokenFee] { selectorFees }
    var feesPublisher: AnyPublisher<[TokenFee], Never> { selectorFeesPublisher }
    var feesHasMultipleFeeOptions: AnyPublisher<Bool, Never> {
        expressInteractor.selectorHasMultipleFeeOptions
    }

    func updateFees() {
        expressInteractor.refresh(type: .fee)
    }
}

// MARK: - FeeSelectorInteractor (ExpressInteractor Proxy)

extension CommonSwapFeeProvider: FeeSelectorInteractor {
    var selectedSelectorFee: TokenFee? { expressInteractor.selectedSelectorFee }
    var selectedSelectorFeePublisher: AnyPublisher<TokenFee?, Never> {
        expressInteractor.selectedSelectorFeePublisher
    }

    var selectorFees: [TokenFee] { expressInteractor.selectorFees }
    var selectorFeesPublisher: AnyPublisher<[TokenFee], Never> {
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

    func userDidSelectFee(_ fee: TokenFee) {
        expressInteractor.userDidSelectFee(fee)
    }

    func userDidSelect(tokenFeeProvider: any TokenFeeProvider) {
        expressInteractor.userDidSelect(tokenFeeProvider: tokenFeeProvider)
    }
}
