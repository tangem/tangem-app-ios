//
//  XRPTransactionHistoryProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import AnyCodable

final class XRPTransactionHistoryProvider: TransactionHistoryProvider {
    private let networkService: XRPNetworkService
    private let mapper: XRPTransactionHistoryMapper
    private let state = OSAllocatedUnfairLock(initialState: State())

    init(
        networkService: XRPNetworkService,
        mapper: XRPTransactionHistoryMapper
    ) {
        self.networkService = networkService
        self.mapper = mapper
    }

    var canFetchHistory: Bool {
        state { !$0.hasReachedEnd }
    }

    var description: String {
        let snapshot = state { $0 }

        return objectDescription(
            self,
            userInfo: [
                "marker": snapshot.marker?.description ?? "-",
                "hasReachedEnd": snapshot.hasReachedEnd,
            ]
        )
    }

    func shouldBeIncludedInHistory(amountType: Amount.AmountType, record: TransactionRecord) -> Bool {
        if case .contractMethodName(let name) = record.type, name == XRPTransaction.TransactionType.trustSet {
            return true
        }

        switch amountType {
        case .coin, .reserve, .feeResource:
            return true
        case .token:
            break
        }

        switch record.destination {
        case .single(let destination):
            return destination.amount != 0
        case .multiple(let destinations):
            return destinations.contains { $0.amount != 0 }
        }
    }

    func loadTransactionHistory(request: TransactionHistory.Request) -> AnyPublisher<TransactionHistory.Response, Error> {
        guard case .address(let address) = request.key else {
            return .anyFail(error: TransactionHistory.ProviderError.requestKeyNotSupported)
        }

        let (resetToken, marker) = state { ($0.resetToken, $0.marker) }

        return networkService
            .getAccountTransactions(
                account: address,
                limit: request.limit,
                marker: marker
            )
            .tryMap { [weak self] response -> TransactionHistory.Response in
                guard let self else {
                    throw BlockchainSdkError.empty
                }

                let records = try mapper.mapToTransactionRecords(
                    response.transactions,
                    walletAddress: address,
                    amountType: request.amountType
                )
                .filter { [weak self] record in
                    guard let self else {
                        return false
                    }

                    return shouldBeIncludedInHistory(
                        amountType: request.amountType,
                        record: record
                    )
                }

                state { state in
                    guard state.resetToken == resetToken else {
                        return
                    }

                    state.marker = response.marker
                    state.hasReachedEnd = response.marker == nil
                }

                return .init(records: records)
            }
            .eraseToAnyPublisher()
    }

    func reset() {
        state { $0 = State() }
        mapper.reset()
    }
}

// MARK: - Auxiliary types

private extension XRPTransactionHistoryProvider {
    struct State {
        /// Changes with every reset, so a response to a request made before the reset can't update the new state.
        let resetToken = UUID()
        var marker: [String: AnyCodable]?
        var hasReachedEnd = false
    }
}
