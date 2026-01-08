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
    private weak var feeProviderInput: TokenFeeProviderInput?

    private let feesProviderFeesLoaders: [SendGeneralFeeProvider]

    private var autoupdatedSuggestedFeeCancellable: AnyCancellable?
    private var cryptoAmountSubscription: AnyCancellable?
    private var destinationAddressSubscription: AnyCancellable?

    init(
        input: SendFeeInput,
        output: SendFeeOutput,
        feeProviderInput: any TokenFeeProviderInput,
        feesProviderFeesLoaders: [SendGeneralFeeProvider],
    ) {
        self.input = input
        self.output = output
        self.feesProviderFeesLoaders = feesProviderFeesLoaders

        bind(feeProviderInput: feeProviderInput)
    }

    private func bind(feeProviderInput: any TokenFeeProviderInput) {
        autoupdatedSuggestedFeeCancellable = autoupdatedSuggestedFee
            .print("->> autoupdatedSuggestedFee")
            .withWeakCaptureOf(self)
            .sink { $0.output?.userDidSelect(selectedFee: $1) }

        cryptoAmountSubscription = Publishers.CombineLatest(
            feeProviderInput.cryptoAmountPublisher,
            feeProviderInput.destinationAddressPublisher,
        )
        .withWeakCaptureOf(self)
        .sink { provider, args in
            provider.feesProviderFeesLoaders.forEach {
                $0.updateData(amount: args.0, destination: args.1)
            }
        }
    }
}

// MARK: - TokenFeeProvider

extension CommonSendFeeProvider: TokenFeeProvider {
    var fees: [TokenFee] {
        feesProviderFeesLoader.fees
    }

    var feesPublisher: AnyPublisher<[TokenFee], Never> {
        feesProviderFeesLoader.feesPublisher
    }

    func updateFees() {
        feesProviderFeesLoader.reloadFees()
    }
}

// MARK: - TokenFeeProvider

// extension CommonSendFeeProvider: TokenFeeProvider {
//    var fees: [TokenFee] {
//        var fees = mapToFees(loadingFees: loadingFees)
//
//        if let customFee = customFeeProvider?.customFee {
//            fees.append(customFee)
//        }
//
//        return fees
//    }
//
//    var feesPublisher: AnyPublisher<[TokenFee], Never> {
//        [
//            loadingFeesPublisher
//                .withWeakCaptureOf(self)
//                .map { $0.mapToFees(loadingFees: $1) }
//                .eraseToAnyPublisher(),
//            customFeeProvider?
//                .customFeePublisher
//                .map { [$0] }
//                .eraseToAnyPublisher(),
//        ]
//        .compactMap(\.self)
//        .combineLatest()
//        .map { $0.flattened().unique() }
//        .eraseToAnyPublisher()
//    }

//    func updateFees() {
//        guard let amount = _cryptoAmount.value, let destination = _destination.value else {
//            assertionFailure("TokenFeeProvider is not ready to update fees")
//            return
//        }
//
//        if feesValueSubject.value.isFailure {
//            feesValueSubject.send(.loading)
//        }
//
//        feeLoadingTask?.cancel()
//        feeLoadingTask = Task {
//            do {
//                let fees = try await feeLoader.getFee(amount: amount, destination: destination)
//                try Task.checkCancellation()
//                feesValueSubject.send(.success(fees))
//            } catch {
//                AppLogger.error("TokenFeeProvider fee loading error", error: error)
//                feesValueSubject.send(.failure(error))
//            }
//        }
//    }
// }

// MARK: - Private

private extension CommonSendFeeProvider {
    var autoupdatedSuggestedFee: AnyPublisher<TokenFee, Never> {
        feesProviderFeesLoader.feesPublisher
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
