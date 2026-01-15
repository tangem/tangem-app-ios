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

    var selectedFeeProviderFees: [LoadableTokenFee] { selectedFeeProvider.fees }
    var selectedFeeProviderFeesPublisher: AnyPublisher<[LoadableTokenFee], Never> {
        selectedFeeProviderPublisher.flatMapLatest(\.feesPublisher).eraseToAnyPublisher()
    }

    var supportedFeeTokenProviders: [any TokenFeeProvider] {
        feeProviders.filter { $0.state.isSupported }
    }

    var supportedFeeTokenProvidersPublisher: AnyPublisher<[any TokenFeeProvider], Never> {
        .just(output: feeProviders)
    }

    func updateSelectedFeeProvider(tokenFeeProvider: any TokenFeeProvider) {
        selectedProviderSubject.send(tokenFeeProvider)
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
