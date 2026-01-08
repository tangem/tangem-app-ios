//
//  CommonSendFeeProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class CommonSendFeeProvider {
    private weak var input: SendFeeInput?
    private weak var output: SendFeeOutput?

    private let feeLoader: TokenFeeLoader
    private let customFeeProvider: (any FeeSelectorCustomFeeProvider)?

    private let initialTokenItem: TokenItem
    private let feesValueSubject: CurrentValueSubject<LoadingResult<[BSDKFee], any Error>, Never> = .init(.loading)

    private let _cryptoAmount: CurrentValueSubject<Decimal?, Never> = .init(nil)
    private let _destination: CurrentValueSubject<String?, Never> = .init(nil)

    private var feeLoadingTask: Task<Void, Never>?
    private var cryptoAmountSubscription: AnyCancellable?
    private var destinationAddressSubscription: AnyCancellable?

    private var customFeeProviderInitialSetupCancellable: AnyCancellable?
    private var autoupdatedSuggestedFeeCancellable: AnyCancellable?

    init(
        input: SendFeeInput,
        output: SendFeeOutput,
        feeProviderInput: any SendFeeProviderInput,
        feeLoader: TokenFeeLoader,
        customFeeProvider: (any FeeSelectorCustomFeeProvider)?,
        initialTokenItem: TokenItem,
    ) {
        self.input = input
        self.output = output
        self.feeLoader = feeLoader
        self.initialTokenItem = initialTokenItem
        self.customFeeProvider = customFeeProvider

        bind(feeProviderInput: feeProviderInput)
    }

    private func bind(feeProviderInput: any SendFeeProviderInput) {
        cryptoAmountSubscription = feeProviderInput.cryptoAmountPublisher
            .eraseToOptional()
            .assign(to: \._cryptoAmount.value, on: self, ownership: .weak)

        destinationAddressSubscription = feeProviderInput
            .destinationAddressPublisher
            .eraseToOptional()
            .assign(to: \._destination.value, on: self, ownership: .weak)

        customFeeProviderInitialSetupCancellable = customFeeProvider?.subscribeToInitialSetup(
            feeProviders: self
        )

        autoupdatedSuggestedFeeCancellable = autoupdatedSuggestedFee
            .print("->> autoupdatedSuggestedFee")
            .withWeakCaptureOf(self)
            .sink { $0.output?.userDidSelect(selectedFee: $1) }
    }
}

// MARK: - StatableTokenFeeProvider

extension CommonSendFeeProvider: StatableTokenFeeProvider {
    var supportingFeeOption: [FeeOption] {
        feeLoader.allowsFeeSelection ? [.slow, .market, .fast] : [.market]
    }

    var feeTokenItem: TokenItem { initialTokenItem }

    var loadingFees: LoadingResult<[BSDKFee], any Error> {
        feesValueSubject.value
    }

    var loadingFeesPublisher: AnyPublisher<LoadingResult<[BSDKFee], any Error>, Never> {
        feesValueSubject.eraseToAnyPublisher()
    }
}

// MARK: - TokenFeeProvider

extension CommonSendFeeProvider: TokenFeeProvider {
    var fees: [TokenFee] {
        var fees = mapToFees(loadingFees: loadingFees)

        if let customFee = customFeeProvider?.customFee {
            fees.append(customFee)
        }

        return fees
    }

    var feesPublisher: AnyPublisher<[TokenFee], Never> {
        [
            loadingFeesPublisher
                .withWeakCaptureOf(self)
                .map { $0.mapToFees(loadingFees: $1) }
                .eraseToAnyPublisher(),
            customFeeProvider?
                .customFeePublisher
                .map { [$0] }
                .eraseToAnyPublisher(),
        ]
        .compactMap(\.self)
        .combineLatest()
        .map { $0.flattened().unique() }
        .eraseToAnyPublisher()
    }
}

// MARK: - SendFeeProvider

extension CommonSendFeeProvider: SendFeeProvider {
    func updateFees() {
        guard let amount = _cryptoAmount.value, let destination = _destination.value else {
            assertionFailure("SendFeeProvider is not ready to update fees")
            return
        }

        if feesValueSubject.value.isFailure {
            feesValueSubject.send(.loading)
        }

        feeLoadingTask?.cancel()
        feeLoadingTask = Task {
            do {
                let fees = try await feeLoader.getFee(amount: amount, destination: destination)
                try Task.checkCancellation()
                feesValueSubject.send(.success(fees))
            } catch {
                AppLogger.error("SendFeeProvider fee loading error", error: error)
                feesValueSubject.send(.failure(error))
            }
        }
    }
}

// MARK: - Private

private extension CommonSendFeeProvider {
    var autoupdatedSuggestedFee: AnyPublisher<TokenFee, Never> {
        feesPublisher
            .withWeakCaptureOf(self)
            .compactMap { feeProvider, fees -> TokenFee? in
                // Custom don't support autoupdate
                let fees = fees.filter { $0.option != .custom }

                // If we have one fee which is failure
                if let failureFee = fees.first(where: { $0.value.isFailure }) {
                    return failureFee
                }

                let hasSelected = feeProvider.input?.selectedFee?.value.value == nil

                // Have loading and non selected
                if let loadingFee = fees.first(where: { $0.value.isLoading }), !hasSelected {
                    return loadingFee
                }

                let selectedFeeOption = hasSelected ? feeProvider.input?.selectedFee?.option : .market

                // All good. Fee just updated
                if let successFee = fees.first(where: { $0.option == selectedFeeOption }) {
                    return successFee
                }

                // First to select the market fee
                return fees.first(where: { $0.option == .market })
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}
