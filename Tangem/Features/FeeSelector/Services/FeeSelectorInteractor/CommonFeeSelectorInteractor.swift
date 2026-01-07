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

    private let feesProvider: any FeeSelectorFeesProvider

    private let feeTokenItemsProvider: (any FeeSelectorFeeTokenItemsProvider)?
    private let suggestedFeeProvider: (any FeeSelectorSuggestedFeeProvider)?
    private let customFeeProvider: (any FeeSelectorCustomFeeProvider)?

    private var customFeeProviderInitialSetupCancellable: AnyCancellable?
    private var autoupdatedSuggestedFeeCancellable: AnyCancellable?

    init(
        input: any FeeSelectorInteractorInput,
        output: any FeeSelectorOutput,
        feesProvider: any FeeSelectorFeesProvider,
        feeTokenItemsProvider: (any FeeSelectorFeeTokenItemsProvider)? = nil,
        suggestedFeeProvider: (any FeeSelectorSuggestedFeeProvider)? = nil,
        customFeeProvider: (any FeeSelectorCustomFeeProvider)? = nil,
    ) {
        self.input = input
        self.output = output
        self.feesProvider = feesProvider
        self.feeTokenItemsProvider = feeTokenItemsProvider
        self.suggestedFeeProvider = suggestedFeeProvider
        self.customFeeProvider = customFeeProvider

        bind()
    }

    private func bind() {
        customFeeProviderInitialSetupCancellable = customFeeProvider?.subscribeToInitialSetup(
            feeProviders: feesProvider
        )

        autoupdatedSuggestedFeeCancellable = autoupdatedSuggestedFee
            .print("->> autoupdatedSuggestedFee \(output)")
            .withWeakCaptureOf(self)
            .sink { $0.output?.userDidSelect(selectedFee: $1) }
    }
}

// MARK: - FeeSelectorInteractor

extension CommonFeeSelectorInteractor: FeeSelectorInteractor {
    var selectedFee: TokenFee? {
        input?.selectedFee
    }

    var selectedFeePublisher: AnyPublisher<TokenFee?, Never> {
        input?.selectedFeePublisher.eraseToOptional().eraseToAnyPublisher() ?? .just(output: .none)
    }

    var fees: [TokenFee] {
        var fees = feesProvider.fees

        if let suggestedFee = suggestedFeeProvider?.suggestedFee {
            fees.append(suggestedFee)
        }

        if let customFee = customFeeProvider?.customFee {
            fees.append(customFee)
        }

        return fees
    }

    var feesPublisher: AnyPublisher<[TokenFee], Never> {
        [
            feesProvider.feesPublisher.eraseToAnyPublisher(),
            suggestedFeeProvider?.suggestedFeePublisher.map { [$0] }.eraseToAnyPublisher(),
            customFeeProvider?.customFeePublisher.map { [$0] }.eraseToAnyPublisher(),
        ]
        .compactMap(\.self)
        .combineLatest()
        .map { $0.flattened().unique() }
        .eraseToAnyPublisher()
    }

    var feeTokenItems: [TokenItem] {
        feeTokenItemsProvider?.tokenItems ?? []
    }

    var feeTokenItemsPublisher: AnyPublisher<[TokenItem], Never> {
        feeTokenItemsProvider?.tokenItemsPublisher ?? .just(output: [])
    }

    func userDidSelect(selectedFee: TokenFee) {
        output?.userDidSelect(selectedFee: selectedFee)
    }
}

// MARK: - Private

private extension CommonFeeSelectorInteractor {}
