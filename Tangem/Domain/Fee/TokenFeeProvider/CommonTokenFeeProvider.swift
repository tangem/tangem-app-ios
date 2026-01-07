//
//  CommonTokenFeeProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class CommonTokenFeeProvider {
    typealias FeesState = LoadingResult<[BSDKFee], any Error>

    private let feeProvider: TokenFeeLoader
    private let feeTokenItem: TokenItem
    private let defaultFeeOptions: [FeeOption]

    private let _cryptoAmount: CurrentValueSubject<Decimal?, Never> = .init(nil)
    private let _destination: CurrentValueSubject<String?, Never> = .init(nil)
    private let _fees: CurrentValueSubject<FeesState, Never> = .init(.loading)

    private var feeLoadingTask: Task<Void, Never>?
    private var cryptoAmountSubscription: AnyCancellable?
    private var destinationAddressSubscription: AnyCancellable?

    init(
        input: TokenFeeProviderInput,
        feeProvider: TokenFeeLoader,
        feeTokenItem: TokenItem,
        defaultFeeOptions: [FeeOption]
    ) {
        self.feeProvider = feeProvider
        self.feeTokenItem = feeTokenItem
        self.defaultFeeOptions = defaultFeeOptions

        bind(input: input)
    }
}

// MARK: - SendFeeProvider

extension CommonTokenFeeProvider: TokenFeeProvider {
    var fees: [TokenFee] {
        mapToFees(state: _fees.value)
    }

    var feesPublisher: AnyPublisher<[TokenFee], Never> {
        _fees
            .withWeakCaptureOf(self)
            .map { $0.mapToFees(state: $1) }
            .eraseToAnyPublisher()
    }

    func updateFees() {
        reloadFees()
    }
}

// MARK: - Private

private extension CommonTokenFeeProvider {
    func bind(input: any TokenFeeProviderInput) {
        cryptoAmountSubscription = input.cryptoAmountPublisher
            .withWeakCaptureOf(self)
            .sink { provider, amount in
                provider._cryptoAmount.send(amount)
            }

        destinationAddressSubscription = input.destinationAddressPublisher
            .withWeakCaptureOf(self)
            .sink { provider, destination in
                provider._destination.send(destination)
            }
    }

    func mapToFees(state: LoadingResult<[BSDKFee], any Error>) -> [TokenFee] {
        switch state {
        case .loading:
            SendFeeConverter.mapToLoadingSendFees(options: defaultFeeOptions, feeTokenItem: feeTokenItem)
        case .failure(let error):
            SendFeeConverter.mapToFailureSendFees(options: defaultFeeOptions, feeTokenItem: feeTokenItem, error: error)
        case .success(let loadedFees):
            SendFeeConverter
                .mapToSendFees(fees: loadedFees, feeTokenItem: feeTokenItem)
                .filter { defaultFeeOptions.contains($0.option) }
        }
    }

    func reloadFees() {
        guard let amount = _cryptoAmount.value, let destination = _destination.value else {
            assertionFailure("SendFeeProvider is not ready to update fees")
            return
        }

        if _fees.value.isFailure {
            _fees.send(.loading)
        }

        feeLoadingTask?.cancel()
        feeLoadingTask = Task {
            do {
                let fees = try await feeProvider.getFee(dataType: .plain(amount: amount, destination: destination))
                try Task.checkCancellation()
                _fees.send(.success(fees))
            } catch {
                AppLogger.error("SendFeeProvider fee loading error", error: error)
                _fees.send(.failure(error))
            }
        }
    }
}
