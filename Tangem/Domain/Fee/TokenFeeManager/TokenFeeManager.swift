//
//  TokenFeeManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

final class TokenFeeManager {
    private let feeProviders: [any TokenFeeProvider]
    private let selectedProviderSubject: CurrentValueSubject<any TokenFeeProvider, Never>

    private var updatingFeeTask: Task<Void, Never>?

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

    func setupFeeProviders(input: TokenFeeProviderInputData) {
        feeProviders.forEach { feeProvider in
            feeProvider.setup(input: input)
        }
    }

    func updateSelectedFeeProviderFees() {
        updatingFeeTask?.cancel()
        updatingFeeTask = Task {
            await selectedFeeProvider.updateFees()
        }
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

    var feesHasMultipleFeeOptions: AnyPublisher<Bool, Never> {
        [
            feesPublisher.map { $0.hasMultipleFeeOptions }.eraseToAnyPublisher(),
            selectedFeeProviderFeeTokenItemsPublisher.map { $0.count > 1 }.eraseToAnyPublisher(),
        ]
        .combineLatest()
        .map { $0.contains(true) }
        .eraseToAnyPublisher()
    }

    func setup(input: TokenFeeProviderInputData) {
        selectedFeeProvider.setup(input: input)
    }

    func updateFees() async {
        await selectedFeeProvider.updateFees()
    }
}

// MARK: - [any TokenFeeProvider]+

extension [any TokenFeeProvider] {
    subscript(_ tokenItem: TokenItem) -> (any TokenFeeProvider)? {
        first { $0.feeTokenItem == tokenItem }
    }
}
