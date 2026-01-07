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

    init(
        feeLoader: TokenFeeLoader,
        customFeeProvider: (any FeeSelectorCustomFeeProvider)?,
        initialTokenItem: TokenItem,
    ) {
        self.feeLoader = feeLoader
        self.initialTokenItem = initialTokenItem
        self.customFeeProvider = customFeeProvider

        customFeeProviderInitialSetupCancellable = customFeeProvider?.subscribeToInitialSetup(
            feeProviders: self
        )
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

// MARK: - SetupableSendFeeProvider

extension CommonSendFeeProvider: SetupableSendFeeProvider {
    func setup(input: any SendFeeProviderInput) {
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
