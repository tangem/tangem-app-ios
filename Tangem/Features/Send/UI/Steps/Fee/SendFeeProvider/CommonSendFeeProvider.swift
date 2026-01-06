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
    private let _fees: CurrentValueSubject<LoadingResult<[TokenFee], Error>, Never> = .init(.loading)

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

        bind(input: input)
    }
}

// MARK: - SendFeeProvider

extension CommonSendFeeProvider: SendFeeProvider {
    var feeOptions: [FeeOption] {
        defaultFeeOptions
    }

    var fees: LoadingResult<[TokenFee], any Error> {
        _fees.value
    }

    var feesPublisher: AnyPublisher<LoadingResult<[TokenFee], any Error>, Never> {
        _fees.eraseToAnyPublisher()
    }

    func updateFees() {
        guard let amount = _cryptoAmount.value, let destination = _destination.value else {
            assertionFailure("SendFeeProvider is not ready to update fees")
            return
        }

        if _fees.value.error != nil {
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

    func mapToDefaultFees(fees: [BSDKFee]) -> [SendFee] {
        switch fees.count {
        case 1:
            return [
                SendFee(option: .market, tokenItem: feeTokenItem, value: .success(fees[0])),
            ]
        // Express estimated fee case
        case 2:
            return [
                SendFee(option: .market, tokenItem: feeTokenItem, value: .success(fees[0])),
                SendFee(option: .fast, tokenItem: feeTokenItem, value: .success(fees[1])),
            ]
        case 3:
            return [
                SendFee(option: .slow, tokenItem: feeTokenItem, value: .success(fees[0])),
                SendFee(option: .market, tokenItem: feeTokenItem, value: .success(fees[1])),
                SendFee(option: .fast, tokenItem: feeTokenItem, value: .success(fees[2])),
            ]
        default:
            assertionFailure("Wrong count of fees")
            return []
        }
    }
}
