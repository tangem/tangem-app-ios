//
//  TokenFeeProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation

final class CommonTokenFeeProvider {
    let feeTokenItem: TokenFeeItem
    private let tokenFeeLoader: any TokenFeeLoader
    private let customFeeProvider: (any CustomFeeProvider)?

    private let feesValueSubject: CurrentValueSubject<LoadingResult<[BSDKFee], any Error>, Never> = .init(.loading)
    private var feesLoadingTask: Task<Void, Never>?

    private var supportingFeeOption: [FeeOption] {
        var supportingFeeOption = tokenFeeLoader.supportingFeeOption

        if customFeeProvider != nil {
            supportingFeeOption.append(.custom)
        }

        return supportingFeeOption
    }

    init(
        feeTokenItem: TokenFeeItem,
        tokenFeeLoader: any TokenFeeLoader,
        customFeeProvider: (any CustomFeeProvider)?
    ) {
        self.feeTokenItem = feeTokenItem
        self.tokenFeeLoader = tokenFeeLoader
        self.customFeeProvider = customFeeProvider
    }
}

// MARK: - TokenFeeProvider

extension CommonTokenFeeProvider: TokenFeeProvider {
    var fees: [TokenFee] {
        mapToFees(loadingFees: feesValueSubject.value)
    }

    var feesPublisher: AnyPublisher<[TokenFee], Never> {
        feesValueSubject
            .withWeakCaptureOf(self)
            .map { $0.mapToFees(loadingFees: $1) }
            .eraseToAnyPublisher()
    }

    func updateFees() {
        feesLoadingTask?.cancel()
        feesLoadingTask = Task {
            /*
            do {
                guard let cryptoAmount, let destination else {
                    throw GeneralFeeProviderError.feesLoaderReqiredDataNotFound
                }

                feesValueSubject.send(.loading)
                let fees = try await tokenFeeLoader.getFee(amount: cryptoAmount, destination: destination)
                try Task.checkCancellation()
                feesValueSubject.send(.success(fees))
            } catch {
                feesValueSubject.send(.failure(error))
            }
             */
        }
    }
}

// MARK: - Private

private extension CommonTokenFeeProvider {
    func mapToFees(loadingFees fees: LoadingResult<[BSDKFee], any Error>) -> [TokenFee] {
        switch fees {
        case .loading:
            TokenFeeConverter.mapToLoadingSendFees(options: supportingFeeOption, feeTokenItem: feeTokenItem)
        case .failure(let error):
            TokenFeeConverter.mapToFailureSendFees(options: supportingFeeOption, feeTokenItem: feeTokenItem, error: error)
        case .success(let loadedFees):
            TokenFeeConverter
                .mapToSendFees(fees: loadedFees, feeTokenItem: feeTokenItem)
                .filter { supportingFeeOption.contains($0.option) }
        }
    }
}

enum GeneralFeeProviderError: LocalizedError {
    case feesLoaderNotFound
    case feesLoaderReqiredDataNotFound
}
