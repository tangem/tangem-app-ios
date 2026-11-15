//
//  EtherscanTransactionHistoryProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemNetworkUtils
import TangemFoundation

final class EtherscanTransactionHistoryProvider<Mapper> where
    Mapper: TransactionHistoryMapper,
    Mapper.Response == EtherscanTransactionHistoryResult,
    Mapper.WalletAddress == String {
    private let mapper: Mapper
    private let networkProvider: TangemProvider<EtherscanTransactionHistoryTarget>
    private let targetConfiguration: EtherscanTransactionHistoryTarget.Configuration
    private let calldataLoader: EtherscanCalldataLoader
    private let state = OSAllocatedUnfairLock(initialState: State())

    init(
        mapper: Mapper,
        networkConfiguration: TangemProviderConfiguration,
        targetConfiguration: EtherscanTransactionHistoryTarget.Configuration
    ) {
        let networkProvider = TangemProvider<EtherscanTransactionHistoryTarget>(
            configuration: networkConfiguration,
            additionalPlugins: [
                CachePolicyPlugin(),
            ]
        )

        self.mapper = mapper
        self.networkProvider = networkProvider
        self.targetConfiguration = targetConfiguration
        calldataLoader = EtherscanCalldataLoader(
            networkProvider: networkProvider,
            targetConfiguration: targetConfiguration
        )
    }

    private func makeTarget(
        for address: String,
        contractAddress: String?,
        limit: Int,
        requestedPageNumber: Int
    ) -> EtherscanTransactionHistoryTarget {
        let target: EtherscanTransactionHistoryTarget.Target
        if let contractAddress {
            target = .getTokenTransactionHistory(
                address: address,
                contract: contractAddress,
                page: requestedPageNumber,
                limit: limit
            )
        } else {
            target = .getCoinTransactionHistory(
                address: address,
                page: requestedPageNumber,
                limit: limit
            )
        }

        return EtherscanTransactionHistoryTarget(configuration: targetConfiguration, target: target)
    }

    private func loadTransactionHistory(
        request: TransactionHistory.Request,
        resetToken: UUID,
        requestedPageNumber: Int?,
        retryAttempt: Int
    ) -> AnyPublisher<TransactionHistory.Response, Error> {
        guard case .address(let address) = request.key else {
            return .anyFail(error: TransactionHistory.ProviderError.requestKeyNotSupported)
        }

        return Deferred { [weak self] in
            Future { promise in
                if let requestedPageNumber {
                    promise(.success(requestedPageNumber))
                } else if let currentPageNumber = self?.state({ $0.page?.number }) {
                    promise(.success(currentPageNumber + 1))
                } else {
                    promise(.success(Constants.initialPageNumber))
                }
            }
        }
        .withWeakCaptureOf(self)
        .flatMap { historyProvider, requestedPageNumber in
            return Just(request)
                .withWeakCaptureOf(historyProvider)
                .map { historyProvider, request in
                    return historyProvider.makeTarget(
                        for: address,
                        contractAddress: request.amountType.token?.contractAddress,
                        limit: request.limit,
                        requestedPageNumber: requestedPageNumber
                    )
                }
                .withWeakCaptureOf(historyProvider)
                .map { historyProvider, target in
                    return historyProvider
                        .networkProvider
                        .requestPublisher(target)
                        .filterSuccessfulStatusAndRedirectCodes()
                        .map(EtherscanTransactionHistoryResult.self)
                        .eraseError()
                }
                .switchToLatest()
                .withWeakCaptureOf(historyProvider)
                .asyncMap { historyProvider, result in
                    await historyProvider.calldataLoader.restoringMissingCalldata(in: result)
                }
                .receiveOnMain()
                .withWeakCaptureOf(historyProvider)
                .tryMap { historyProvider, result in
                    let transactionRecords = try historyProvider
                        .mapper
                        .mapToTransactionRecords(result, walletAddress: address, amountType: request.amountType)
                        .filter { record in
                            historyProvider.shouldBeIncludedInHistory(
                                amountType: request.amountType,
                                record: record
                            )
                        }
                    historyProvider.state { state in
                        guard state.resetToken == resetToken else {
                            return
                        }

                        state.page = TransactionHistoryIndexPage(number: requestedPageNumber)
                    }

                    return TransactionHistory.Response(records: transactionRecords)
                }
                .tryCatch { [weak historyProvider] error in
                    return historyProvider
                        .publisher
                        .flatMap { historyProvider in
                            return historyProvider.handleLoadTransactionHistoryError(
                                error,
                                request: request,
                                resetToken: resetToken,
                                requestedPageNumber: requestedPageNumber,
                                retryAttempt: retryAttempt
                            )
                        }
                }
        }
        .eraseToAnyPublisher()
    }

    private func handleLoadTransactionHistoryError(
        _ error: Error,
        request: TransactionHistory.Request,
        resetToken: UUID,
        requestedPageNumber: Int,
        retryAttempt: Int
    ) -> AnyPublisher<TransactionHistory.Response, Error> {
        guard let error = error as? EtherscanAPIError else {
            return .anyFail(error: error)
        }

        switch error {
        case .maxRateLimitReached where retryAttempt < Constants.maxRetryCount:
            let nextRetryAttempt = retryAttempt + 1
            let retryInterval = ExponentialBackoffInterval(retryAttempt: nextRetryAttempt)

            return Just(())
                .delay(for: .init(.nanoseconds(Int(retryInterval()))), scheduler: DispatchQueue.main)
                .withWeakCaptureOf(self)
                .flatMap { historyProvider, _ in
                    return historyProvider.loadTransactionHistory(
                        request: request,
                        resetToken: resetToken,
                        requestedPageNumber: requestedPageNumber,
                        retryAttempt: nextRetryAttempt
                    )
                }
                .eraseToAnyPublisher()
        case .endOfTransactionHistoryReached:
            state { state in
                guard state.resetToken == resetToken else {
                    return
                }

                state.page = TransactionHistoryIndexPage(number: requestedPageNumber)
                state.hasReachedEnd = true
            }

            return .justWithError(output: TransactionHistory.Response(records: []))
        case .unknown, .maxRateLimitReached:
            return .anyFail(error: error)
        }
    }
}

// MARK: - TransactionHistoryProvider protocol conformance

extension EtherscanTransactionHistoryProvider: TransactionHistoryProvider {
    var description: String {
        let snapshot = state { $0 }

        return objectDescription(
            self,
            userInfo: [
                "pageNumber": snapshot.page?.number ?? "nil",
                "hasReachedEnd": snapshot.hasReachedEnd,
            ]
        )
    }

    var canFetchHistory: Bool {
        state { state in
            state.page == nil || !state.hasReachedEnd
        }
    }

    func loadTransactionHistory(request: TransactionHistory.Request) -> AnyPublisher<TransactionHistory.Response, Error> {
        guard case .address = request.key else {
            return .anyFail(error: TransactionHistory.ProviderError.requestKeyNotSupported)
        }

        let resetToken = state { $0.resetToken }

        return loadTransactionHistory(request: request, resetToken: resetToken, requestedPageNumber: nil, retryAttempt: 0)
    }

    func reset() {
        mapper.reset()
        state { $0 = State() }
    }
}

// MARK: - Auxiliary types

private extension EtherscanTransactionHistoryProvider {
    struct State {
        /// Changes with every reset, so a response to a request made before the reset can't update the new state.
        let resetToken = UUID()
        var page: TransactionHistoryIndexPage?
        var hasReachedEnd = false
    }
}

// MARK: - Constants

private extension EtherscanTransactionHistoryProvider {
    enum Constants {
        // - Note: Tx history API has 1-based indexing (not 0-based indexing)
        static var initialPageNumber: Int { 1 }
        static var maxRetryCount: Int { 3 }
    }
}
