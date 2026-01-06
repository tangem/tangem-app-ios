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
    private let input: any FeeSelectorInteractorInput
    private let feeTokenItemsProvider: any FeeSelectorFeeTokenItemsProvider
    private let feesProvider: any FeeSelectorFeesProvider
    private let suggestedFeeProvider: (any FeeSelectorSuggestedFeeProvider)?
    private let customFeeProvider: (any FeeSelectorCustomFeeProvider)?

    private var customFeeProviderInitialSetupCancellable: AnyCancellable?

    init(
        input: any FeeSelectorInteractorInput,
        feeTokenItemsProvider: any FeeSelectorFeeTokenItemsProvider,
        feesProvider: any FeeSelectorFeesProvider,
        suggestedFeeProvider: (any FeeSelectorSuggestedFeeProvider)?,
        customFeeProvider: (any FeeSelectorCustomFeeProvider)?
    ) {
        self.input = input
        self.feeTokenItemsProvider = feeTokenItemsProvider
        self.feesProvider = feesProvider
        self.suggestedFeeProvider = suggestedFeeProvider
        self.customFeeProvider = customFeeProvider

        customFeeProviderInitialSetupCancellable = customFeeProvider?.subscribeToInitialSetup(feeProvider: self)
    }
}

// MARK: - FeeSelectorInteractor

extension CommonFeeSelectorInteractor: FeeSelectorInteractor {
    var selectedFee: SendFee {
        input.selectedFee
    }

    var selectedFeePublisher: AnyPublisher<SendFee, Never> {
        input.selectedFeePublisher
    }

    var fees: [SendFee] {
        var fees = feesProvider.fees

        if let suggestedFee = suggestedFeeProvider?.suggestedFee {
            fees.append(suggestedFee)
        }

        if let customFee = customFeeProvider?.customFee {
            fees.append(customFee)
        }

        return fees
    }

    var feesPublisher: AnyPublisher<[SendFee], Never> {
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
}

// MARK: - FeeSelectorFeesDataProvider

extension CommonFeeSelectorInteractor: FeeSelectorFeesDataProvider {
    var selectedSelectorFee: SendFee {
        mapToFeeSelectorFee(fee: selectedFee)
    }

    var selectedSelectorFeePublisher: AnyPublisher<SendFee, Never> {
        selectedFeePublisher
            .withWeakCaptureOf(self)
            .map { $0.mapToFeeSelectorFee(fee: $1) }
            .eraseToAnyPublisher()
    }

    var selectorFees: [SendFee] {
        fees.map { mapToFeeSelectorFee(fee: $0) }
    }

    var selectorFeesPublisher: AnyPublisher<[SendFee], Never> {
        feesPublisher
            .withWeakCaptureOf(self)
            .map { $0.mapToFeeSelectorFees(fees: $1) }
            .eraseToAnyPublisher()
    }
}

// MARK: - FeeSelectorTokensDataProvider

extension CommonFeeSelectorInteractor: FeeSelectorTokensDataProvider {
    var selectedFeeTokenItem: TokenItem {
        selectedFee.tokenItem
    }

    var selectedFeeTokenItemPublisher: AnyPublisher<TokenItem, Never> {
        selectedFeePublisher.map(\.tokenItem).eraseToAnyPublisher()
    }

    var feeTokenItems: [TokenItem] {
        feeTokenItemsProvider.tokenItems
    }

    var feeTokenItemsPublisher: AnyPublisher<[TokenItem], Never> {
        feeTokenItemsProvider.tokenItemsPublisher
    }
}

// MARK: - Private

private extension CommonFeeSelectorInteractor {
    func mapToFeeSelectorFees(fees: [SendFee]) -> [SendFee] {
        fees.map(mapToFeeSelectorFee)
    }

    func mapToFeeSelectorFee(fee: SendFee) -> SendFee {
        return SendFee(option: fee.option, tokenItem: fee.tokenItem, value: fee.value)
    }
}
