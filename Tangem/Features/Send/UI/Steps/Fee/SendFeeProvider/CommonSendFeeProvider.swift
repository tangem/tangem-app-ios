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
    private weak var input: SendFeeInput?
    private weak var output: SendFeeOutput?
    private let tokenFeeManager: TokenFeeManager

    private var amount: Decimal?
    private var destination: String?

    private var autoupdatedSuggestedFeeCancellable: AnyCancellable?
    private var cryptoAmountSubscription: AnyCancellable?
    private var destinationAddressSubscription: AnyCancellable?

    init(input: SendFeeInput, output: SendFeeOutput, dataInput: SendFeeProviderInput, tokenFeeManager: TokenFeeManager) {
        self.input = input
        self.output = output
        self.tokenFeeManager = tokenFeeManager

        bind(dataInput: dataInput)
        bind()
    }

    private func bind(dataInput: any SendFeeProviderInput) {
        cryptoAmountSubscription = dataInput.cryptoAmountPublisher
            .eraseToOptional()
            .assign(to: \.amount, on: self, ownership: .weak)

        destinationAddressSubscription = dataInput.destinationAddressPublisher
            .eraseToOptional()
            .assign(to: \.destination, on: self, ownership: .weak)
    }

    private func bind() {
        autoupdatedSuggestedFeeCancellable = feesPublisher
            .withWeakCaptureOf(self)
            .compactMap { feeProvider, fees -> TokenFee? in
                // Custom don't support autoupdate
                let fees = fees.filter { $0.option != .custom }

                // If we have one fee which is failure
                if let failureFee = fees.first(where: { $0.value.isFailure }) {
                    return failureFee
                }

                let hasSelected = feeProvider.input?.selectedFee.value.value == nil

                // Have loading and non selected
                if let loadingFee = fees.first(where: { $0.value.isLoading }), !hasSelected {
                    return loadingFee
                }

                let selectedFeeOption = hasSelected ? feeProvider.input?.selectedFee.option : .market

                // All good. Fee just updated
                if let successFee = fees.first(where: { $0.option == selectedFeeOption }) {
                    return successFee
                }

                // First to select the market fee
                return fees.first(where: { $0.option == .market })
            }
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { $0.output?.feeDidChanged(fee: $1) }
    }
}

// MARK: - SendFeeProvider

extension CommonSendFeeProvider: SendFeeProvider {
    var fees: [TokenFee] { tokenFeeManager.selectedFeeProviderFees }
    var feesPublisher: AnyPublisher<[TokenFee], Never> { tokenFeeManager.selectedFeeProviderFeesPublisher }

    var feesHasMultipleFeeOptions: AnyPublisher<Bool, Never> {
        selectorHasMultipleFeeOptions
    }

    func updateFees() {
        guard let amount, let destination else {
            assertionFailure("SendFeeProvider is not ready to update fees")
            return
        }

        tokenFeeManager.setupFeeProviders(input: .common(amount: amount, destination: destination))
        tokenFeeManager.updateSelectedFeeProviderFees()
    }
}

// MARK: - FeeSelectorInteractor

extension CommonSendFeeProvider: FeeSelectorInteractor {
    var selectedSelectorFee: TokenFee? { input?.selectedFee }
    var selectedSelectorFeePublisher: AnyPublisher<TokenFee?, Never> {
        input?.selectedFeePublisher.eraseToOptional().eraseToAnyPublisher() ?? .just(output: .none)
    }

    var selectorFees: [TokenFee] { tokenFeeManager.selectedFeeProviderFees }
    var selectorFeesPublisher: AnyPublisher<[TokenFee], Never> {
        tokenFeeManager.selectedFeeProviderFeesPublisher
    }

    var selectedSelectorTokenFeeProvider: (any TokenFeeProvider)? { tokenFeeManager.selectedFeeProvider }
    var selectedSelectorTokenFeeProviderPublisher: AnyPublisher<(any TokenFeeProvider)?, Never> {
        tokenFeeManager.selectedFeeProviderPublisher.eraseToOptional().eraseToAnyPublisher()
    }

    var selectorTokenFeeProviders: [any TokenFeeProvider] { tokenFeeManager.supportedFeeTokenProviders }
    var selectorTokenFeeProvidersPublisher: AnyPublisher<[any TokenFeeProvider], Never> {
        tokenFeeManager.supportedFeeTokenProvidersPublisher
    }

    var customFeeProvider: (any CustomFeeProvider)? {
        (tokenFeeManager.selectedFeeProvider as? FeeSelectorCustomFeeDataProviding)?.customFeeProvider
    }

    func userDidSelectFee(_ fee: TokenFee) {
        output?.feeDidChanged(fee: fee)
    }

    func userDidSelect(tokenFeeProvider: any TokenFeeProvider) {
        tokenFeeManager.updateSelectedFeeProvider(tokenFeeProvider: tokenFeeProvider)
        tokenFeeManager.updateSelectedFeeProviderFees()
    }
}
