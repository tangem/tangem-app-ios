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
    private let _feeTokenItem: TokenItem
    private let _defaultFeeOptions: [FeeOption]

    private let _cryptoAmount: CurrentValueSubject<Decimal?, Never> = .init(nil)
    private let _destination: CurrentValueSubject<String?, Never> = .init(nil)
    private let _fees: CurrentValueSubject<FeesState, Never>

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
        _feeTokenItem = feeTokenItem
        _defaultFeeOptions = defaultFeeOptions

        _fees = .init(FeesState(feeTokenItem: _feeTokenItem, options: _defaultFeeOptions, state: .loading))

        bind(input: input)
    }
}

// MARK: - SendFeeProvider

extension CommonSendFeeProvider: SendFeeProvider {
//    var feeOptions: [FeeOption] {
//        _defaultFeeOptions
//    }
//
//    var feeTokenItem: TokenItem {
//        _feeTokenItem
//    }

    var fees: LoadableFees {
        _fees.value.fees
    }

    var feesPublisher: AnyPublisher<LoadableFees, Never> {
        _fees.map { $0.fees }.eraseToAnyPublisher()
    }

    func updateFees() {
        guard let amount = _cryptoAmount.value, let destination = _destination.value else {
            assertionFailure("SendFeeProvider is not ready to update fees")
            return
        }

        if _fees.value.isError {
            _fees.value.update(state: .loading)
        }

        feeLoadingTask?.cancel()
        feeLoadingTask = Task {
            do {
                let fees = try await feeProvider.getFee(dataType: .plain(amount: amount, destination: destination))
                try Task.checkCancellation()
                _fees.value.update(state: .success(fees))
            } catch {
                AppLogger.error("SendFeeProvider fee loading error", error: error)
                _fees.value.update(state: .failure(error))
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
}

private struct FeesState {
    let feeTokenItem: TokenItem
    let options: [FeeOption]

    var error: (any Error)? { state.error }
    var isLoading: Bool { state.isLoading }
    var isError: Bool { state.isFailure }

    private var state: LoadingResult<[BSDKFee], any Error>

    init(feeTokenItem: TokenItem, options: [FeeOption], state: LoadingResult<[BSDKFee], any Error>) {
        self.feeTokenItem = feeTokenItem
        self.options = options
        self.state = state
    }

    mutating func update(state: LoadingResult<[BSDKFee], any Error>) {
        self.state = state
    }

    func marketFee() throws -> SendFee {
        guard options.count == 1 else {
            // Wrong count fees. TODO
            throw CommonError.noData
        }

        switch state {
        case .loading:
            return SendFee(option: .market, tokenItem: feeTokenItem, value: .loading)
        case .failure(let error):
            return SendFee(option: .market, tokenItem: feeTokenItem, value: .failure(error))
        case .success(let loadedFees) where loadedFees.count == 1:
            return SendFee(option: .market, tokenItem: feeTokenItem, value: .success(loadedFees[0]))
        case .success:
            // Wrong count fees. TODO
            throw CommonError.noData
        }
    }

    var fees: [SendFee] {
        switch state {
        case .loading:
            options.map { SendFee(option: $0, tokenItem: feeTokenItem, value: .loading) }
        case .failure(let error):
            options.map { SendFee(option: $0, tokenItem: feeTokenItem, value: .failure(error)) }
        case .success(let loadedFees):
            SendFeeConverter
                .mapToSendFees(fees: loadedFees, feeTokenItem: feeTokenItem)
                .filter { options.contains($0.option) }
        }
    }
}
