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

    var selectedFeeProviderFees: [TokenFee] { selectedFeeProvider.fees }
    var selectedFeeProviderFeesPublisher: AnyPublisher<[TokenFee], Never> {
        selectedFeeProviderPublisher.flatMapLatest(\.feesPublisher).eraseToAnyPublisher()
    }

    var selectedFeeProviderFeeTokenItems: [TokenItem] { feeProviders.map(\.feeTokenItem) }
    var selectedFeeProviderFeeTokenItemsPublisher: AnyPublisher<[TokenItem], Never> {
        .just(output: selectedFeeProviderFeeTokenItems)
    }

    func updateSelectedFeeProvider(tokenItem: TokenItem) {
        guard let feeProvider = feeProviders[tokenItem] else {
            assertionFailure("Fee provider for token item \(tokenItem) not found")
            return
        }

        selectedProviderSubject.send(feeProvider)
    }
}

// MARK: - TokenFeeProvider

extension TokenFeeManager: TokenFeeProvider {
    var feeTokenItem: TokenItem { selectedFeeProvider.feeTokenItem }

    var state: TokenFeeProviderState { selectedFeeProvider.state }
    var statePublisher: AnyPublisher<TokenFeeProviderState, Never> {
        selectedFeeProviderPublisher.flatMapLatest(\.statePublisher).eraseToAnyPublisher()
    }

    var fees: [TokenFee] { selectedFeeProvider.fees }
    var feesPublisher: AnyPublisher<[TokenFee], Never> {
        selectedFeeProviderPublisher.flatMapLatest(\.feesPublisher).eraseToAnyPublisher()
    }
}
