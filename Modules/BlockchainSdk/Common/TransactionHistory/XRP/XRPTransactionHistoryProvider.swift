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

    private var marker: [String: AnyCodable]?
    private var hasReachedEnd: Bool = false

    init(
        networkService: XRPNetworkService,
        mapper: XRPTransactionHistoryMapper
    ) {
        self.networkService = networkService
        self.mapper = mapper
    }

    var canFetchHistory: Bool {
        !hasReachedEnd
    }

    var description: String {
        objectDescription(
            self,
            userInfo: [
                "marker": marker?.description ?? "-",
                "hasReachedEnd": hasReachedEnd,
            ]
        )
    }

    func loadTransactionHistory(request: TransactionHistory.Request) -> AnyPublisher<TransactionHistory.Response, Error> {
        guard case .address(let address) = request.key else {
            return .anyFail(error: TransactionHistory.ProviderError.requestKeyNotSupported)
        }

        return networkService
            .getAccountTransactions(
                account: address,
                limit: request.limit,
                marker: marker
            )
            .handleEvents(receiveOutput: { [weak self] response in
                self?.marker = response.marker
                self?.hasReachedEnd = response.marker == nil
            })
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

                return .init(records: records)
            }
            .eraseToAnyPublisher()
    }

    func reset() {
        marker = nil
        hasReachedEnd = false
        mapper.reset()
    }
}
