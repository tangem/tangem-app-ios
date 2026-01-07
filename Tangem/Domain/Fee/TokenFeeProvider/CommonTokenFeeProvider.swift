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

    private let feeLoader: TokenFeeLoader
    private let feeTokenItem: TokenItem
    private let defaultFeeOptions: [FeeOption]

    private let _fees: CurrentValueSubject<FeesState, Never> = .init(.loading)
    private var feeLoadingTask: Task<Void, Never>?

    init(
        feeLoader: TokenFeeLoader,
        feeTokenItem: TokenItem,
        defaultFeeOptions: [FeeOption]
    ) {
        self.feeLoader = feeLoader
        self.feeTokenItem = feeTokenItem
        self.defaultFeeOptions = defaultFeeOptions
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

    func reloadFees(request: TokenFeeProviderFeeRequest) {
        if _fees.value.isFailure {
            _fees.send(.loading)
        }

        feeLoadingTask?.cancel()
        feeLoadingTask = Task {
            do {
                let fees = try await feeLoader.getFee(dataType: .plain(amount: request.amount, destination: request.destination))
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

private extension CommonTokenFeeProvider {
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
}
