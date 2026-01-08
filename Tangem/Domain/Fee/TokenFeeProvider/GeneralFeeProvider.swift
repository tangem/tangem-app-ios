//
//  GeneralFeeProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation

extension WalletModel {
    func generalFeeProviderBuilder() -> GeneralFeeProviderBuilder {
        .init(walletModel: self)
    }
}

struct GeneralFeeProviderBuilder {
    let walletModel: any WalletModel

    func makeGeneralFeeProviders() -> [SendGeneralFeeProvider] {
        let supportedFeeTokenItems = [walletModel] // [REDACTED_TODO_COMMENT]

        return supportedFeeTokenItems.map { walletModel in
            CommonGeneralFeeProvider(
                feeTokenItem: walletModel.feeTokenItem,
                tokenFeeLoader: walletModel.tokenFeeLoader,
                customFeeProvider: walletModel.customFeeProvider,
            )
        }
    }
}

protocol GeneralFeeProvider {
    var feeItem: TokenFeeItem { get }

    var fees: [TokenFee] { get }
    var feesPublisher: AnyPublisher<[TokenFee], Never> { get }

    func reloadFees()
}

protocol SendGeneralFeeProvider: GeneralFeeProvider {
    func updateData(amount: Decimal, destination: String)
}

// extension GeneralFeeProvider {
//    func startUpdateFees() {
//        Task { await updateFees() }
//    }
// }

final class CommonGeneralFeeProvider {
    private let feeTokenItem: TokenFeeItem
    private let tokenFeeLoader: any TokenFeeLoader
    private let customFeeProvider: (any CustomFeeProvider)?

    private var cryptoAmount: Decimal?
    private var destination: String?

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

// MARK: - GeneralFeeProvider

extension CommonGeneralFeeProvider: GeneralFeeProvider {
    var feeItem: TokenFeeItem { feeTokenItem }

    var fees: [TokenFee] {
        mapToFees(loadingFees: feesValueSubject.value)
    }

    var feesPublisher: AnyPublisher<[TokenFee], Never> {
        feesValueSubject
            .withWeakCaptureOf(self)
            .map { $0.mapToFees(loadingFees: $1) }
            .eraseToAnyPublisher()
    }

    func reloadFees() {
        feesLoadingTask?.cancel()
        feesLoadingTask = Task {
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
        }
    }
}

// MARK: - SendGeneralFeeProvider

extension CommonGeneralFeeProvider: SendGeneralFeeProvider {
    func updateData(amount: Decimal, destination: String) {
        self.cryptoAmount = amount
        self.destination = destination
    }
}

// MARK: - Private

private extension CommonGeneralFeeProvider {
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
