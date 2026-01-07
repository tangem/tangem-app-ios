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

    private let feesProvider: any TokenFeeProvider
    private var autoupdatedSuggestedFeeCancellable: AnyCancellable?

    init(
        input: any FeeSelectorInteractorInput,
        output: any FeeSelectorOutput,
        feesProvider: any TokenFeeProvider,
    ) {
        self.input = input
        self.output = output
        self.feesProvider = feesProvider

        bind()
    }

    private func bind() {
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
        feesProvider.fees
    }

    var feesPublisher: AnyPublisher<[TokenFee], Never> {
        feesProvider.feesPublisher
    }

    var feeTokenItems: [TokenItem] {
        (feesProvider as? UpdatableSimpleTokenFeeProvider)?.tokenItems ?? []
    }

    var feeTokenItemsPublisher: AnyPublisher<[TokenItem], Never> {
        (feesProvider as? UpdatableSimpleTokenFeeProvider)?.tokenItemsPublisher ?? .just(output: [])
    }

    func userDidSelect(feeTokenItem: TokenItem) {
        (feesProvider as? UpdatableSimpleTokenFeeProvider)?.userDidSelectTokenItem(feeTokenItem)
    }

    func userDidSelect(selectedFee: TokenFee) {
        output?.userDidSelect(selectedFee: selectedFee)
    }
}

// MARK: - Private

private extension CommonFeeSelectorInteractor {}
