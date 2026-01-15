//
//  CommonSendFeeProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class CommonSendFeeProvider {
    private unowned var sourceTokenInput: SendSourceTokenInput
    private unowned var sendFeeUpdater: SendFeeUpdater

    private var amount: Decimal?
    private var destination: String?

    private var autoupdatedSuggestedFeeCancellable: AnyCancellable?
    private var cryptoAmountSubscription: AnyCancellable?
    private var destinationAddressSubscription: AnyCancellable?

    init(sourceTokenInput: SendSourceTokenInput, sendFeeUpdater: SendFeeUpdater) {
        self.sourceTokenInput = sourceTokenInput
        self.sendFeeUpdater = sendFeeUpdater

        bind()
    }

    private func bind() {
        autoupdatedSuggestedFeeCancellable = sourceTokenInput.sourceToken.tokenFeeManager
            .selectedFeeProviderFeesPublisher
            .withWeakCaptureOf(self)
            .compactMap { feeProvider, fees -> LoadableTokenFee? in
                // Custom don't support autoupdate
                let fees = fees.filter { $0.option != .custom }

                // If we have one fee which is failure
                if let failureFee = fees.first(where: { $0.value.isFailure }) {
                    return failureFee
                }

                let selectedFee = feeProvider.sourceTokenInput.sourceToken.tokenFeeManager.selectedLoadableFee
                let hasSelected = selectedFee.value.value == nil

                // Have loading and non selected
                if let loadingFee = fees.first(where: { $0.value.isLoading }), !hasSelected {
                    return loadingFee
                }

                let selectedFeeOption = hasSelected ? selectedFee.option : .market

                // All good. Fee just updated
                if let successFee = fees.first(where: { $0.option == selectedFeeOption }) {
                    return successFee
                }

                // First to select the market fee
                return fees.first(where: { $0.option == .market })
            }
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink {
                $0.sourceTokenInput.sourceToken.tokenFeeManager.updateSelectedFeeOption(feeOption: $1.option)
            }
    }
}

// MARK: - SendFeeUpdater

extension CommonSendFeeProvider: SendFeeUpdater {
    func updateFees() {
        sendFeeUpdater.updateFees()
    }
}

// MARK: - FeeSelectorInteractor

extension CommonSendFeeProvider: FeeSelectorInteractor {
    var selectedSelectorFee: LoadableTokenFee? { sourceTokenInput.sourceToken.tokenFeeManager.selectedLoadableFee }
    var selectedSelectorFeePublisher: AnyPublisher<LoadableTokenFee?, Never> {
        sourceTokenInput.sourceToken.tokenFeeManager.selectedLoadableFeePublisher.eraseToOptional().eraseToAnyPublisher()
    }

    var selectorFees: [LoadableTokenFee] { sourceTokenInput.sourceToken.tokenFeeManager.selectedFeeProviderFees }
    var selectorFeesPublisher: AnyPublisher<[LoadableTokenFee], Never> {
        sourceTokenInput.sourceToken.tokenFeeManager.selectedFeeProviderFeesPublisher
    }

    var selectedSelectorTokenFeeProvider: (any TokenFeeProvider)? { sourceTokenInput.sourceToken.tokenFeeManager.selectedFeeProvider }
    var selectedSelectorTokenFeeProviderPublisher: AnyPublisher<(any TokenFeeProvider)?, Never> {
        sourceTokenInput.sourceToken.tokenFeeManager.selectedFeeProviderPublisher.eraseToOptional().eraseToAnyPublisher()
    }

    var selectorTokenFeeProviders: [any TokenFeeProvider] { sourceTokenInput.sourceToken.tokenFeeManager.supportedFeeTokenProviders }
    var selectorTokenFeeProvidersPublisher: AnyPublisher<[any TokenFeeProvider], Never> {
        sourceTokenInput.sourceToken.tokenFeeManager.supportedFeeTokenProvidersPublisher
    }

    var customFeeProvider: (any CustomFeeProvider)? {
        (sourceTokenInput.sourceToken.tokenFeeManager.selectedFeeProvider as? FeeSelectorCustomFeeDataProviding)?.customFeeProvider
    }

    func userDidSelectFee(_ fee: LoadableTokenFee) {
        sourceTokenInput.sourceToken.tokenFeeManager.updateSelectedFeeOption(feeOption: fee.option)
    }

    func userDidSelect(tokenFeeProvider: any TokenFeeProvider) {
        sourceTokenInput.sourceToken.tokenFeeManager.updateSelectedFeeProvider(tokenFeeProvider: tokenFeeProvider)
        sourceTokenInput.sourceToken.tokenFeeManager.updateSelectedFeeProviderFees()
    }
}
