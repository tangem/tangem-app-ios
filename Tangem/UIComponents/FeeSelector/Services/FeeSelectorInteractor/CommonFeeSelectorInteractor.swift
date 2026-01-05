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
    private let feesProvider: any FeeSelectorFeesProvider
    private let suggestedFeeProvider: (any FeeSelectorSuggestedFeeProvider)?
    private let customFeeProvider: (any FeeSelectorCustomFeeProvider)?

    private var customFeeProviderInitialSetupCancellable: AnyCancellable?

    init(
        input: any FeeSelectorInteractorInput,
        feesProvider: any FeeSelectorFeesProvider,
        suggestedFeeProvider: (any FeeSelectorSuggestedFeeProvider)?,
        customFeeProvider: (any FeeSelectorCustomFeeProvider)?
    ) {
        self.input = input
        self.feesProvider = feesProvider
        self.suggestedFeeProvider = suggestedFeeProvider
        self.customFeeProvider = customFeeProvider

        customFeeProviderInitialSetupCancellable = customFeeProvider?.subscribeToInitialSetup(feeProvider: self)
    }
}

// MARK: - FeeSelectorFeesDataProvider

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
    var selectedSelectorFee: FeeSelectorFee {
        mapToFeeSelectorFee(fee: selectedFee)
    }

    var selectedSelectorFeePublisher: AnyPublisher<FeeSelectorFee, Never> {
        selectedFeePublisher
            .withWeakCaptureOf(self)
            .map { $0.mapToFeeSelectorFee(fee: $1) }
            .eraseToAnyPublisher()
    }

    var selectorFees: [FeeSelectorFee] {
        fees.map { mapToFeeSelectorFee(fee: $0) }
    }

    var selectorFeesPublisher: AnyPublisher<[FeeSelectorFee], Never> {
        feesPublisher
            .withWeakCaptureOf(self)
            .map { $0.mapToFeeSelectorFees(fees: $1) }
            .eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension CommonFeeSelectorInteractor {
    func mapToFeeSelectorFees(fees: [SendFee]) -> [FeeSelectorFee] {
        fees.map(mapToFeeSelectorFee)
    }

    func mapToFeeSelectorFee(fee: SendFee) -> FeeSelectorFee {
        return FeeSelectorFee(option: fee.option, value: fee.value)
    }
}
