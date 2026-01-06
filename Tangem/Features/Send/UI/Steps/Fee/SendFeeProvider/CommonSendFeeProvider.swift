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
    private weak var input: SendFeeProviderInput?

    private let feeProvider: TokenFeeProvider
    private let feeTokenItem: TokenItem
    private let defaultFeeOptions: [FeeOption]

    private let _cryptoAmount: CurrentValueSubject<Decimal?, Never> = .init(nil)
    private let _destination: CurrentValueSubject<String?, Never> = .init(nil)
    private let _fees: CurrentValueSubject<LoadingResult<[BSDKFee], any Error>, Never>

    private var feeLoadingTask: Task<Void, Never>?
    private var cryptoAmountSubscription: AnyCancellable?
    private var destinationAddressSubscription: AnyCancellable?

    init(
        input: any SendFeeProviderInput,
        feeProvider: TokenFeeProvider,
        feeTokenItem: TokenItem,
        defaultFeeOptions: [FeeOption]
    ) {
        self.input = input
        self.feeProvider = feeProvider
        self.feeTokenItem = feeTokenItem
        self.defaultFeeOptions = defaultFeeOptions

        _fees = .init(.loading)

        bind(input: input)
    }
}

// MARK: - SendFeeProvider

extension CommonSendFeeProvider: SendFeeProvider {
    var fees: [SendFee] {
        mapToFees(state: _fees.value)
    }

    var feesPublisher: AnyPublisher<[SendFee], Never> {
        _fees
            .withWeakCaptureOf(self)
            .map { $0.mapToFees(state: $1) }
            .eraseToAnyPublisher()
    }

    func updateFees() {
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

// MARK: - Private

private extension CommonSendFeeProvider {
    func bind(input: any SendFeeProviderInput) {
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

    func mapToFees(state: LoadingResult<[BSDKFee], any Error>) -> [SendFee] {
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
}
