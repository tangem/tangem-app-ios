//
//  TokenFeeManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

extension [any TokenFeeProvider] {
    subscript(_ tokenItem: TokenItem) -> (any TokenFeeProvider)? {
        first { $0.feeTokenItem == tokenItem }
    }
}

final class TokenFeeManager {
    private let feeProviders: [any TokenFeeProvider]
    private let selectedProviderSubject: CurrentValueSubject<any TokenFeeProvider, Never>

    init(
        feeProviders: [any TokenFeeProvider],
        initialSelectedProvider: any TokenFeeProvider
    ) {
        self.feeProviders = feeProviders
        selectedProviderSubject = .init(initialSelectedProvider)
    }
}

// MARK: - Public

extension TokenFeeManager {
    var selectedFeeProvider: any TokenFeeProvider {
        selectedProviderSubject.value
    }

    var selectedFeeProviderPublisher: AnyPublisher<any TokenFeeProvider, Never> {
        selectedProviderSubject.eraseToAnyPublisher()
    }
}

// MARK: - FeeSelectorTokensDataProvider

extension TokenFeeManager: FeeSelectorTokensDataProvider {
    var selectedSelectorFeeTokenItem: TokenItem? { selectedFeeProvider.feeTokenItem }
    var selectedSelectorFeeTokenItemPublisher: AnyPublisher<TokenItem?, Never> {
        selectedProviderSubject.map { $0.feeTokenItem }.eraseToAnyPublisher()
    }

    var selectorFeeTokenItems: [TokenItem] { feeProviders.map(\.feeTokenItem) }
    var selectorFeeTokenItemsPublisher: AnyPublisher<[TokenItem], Never> { .just(output: selectorFeeTokenItems) }
}

// MARK: - TokenFeeProvider

extension TokenFeeManager: TokenFeeProvider {
    var feeTokenItem: TokenItem { selectedFeeProvider.feeTokenItem }
    var state: TokenFeeProviderState { selectedFeeProvider.state }
    var statePublisher: AnyPublisher<TokenFeeProviderState, Never> {
        selectedProviderSubject.flatMapLatest { $0.statePublisher }.eraseToAnyPublisher()
    }
}
