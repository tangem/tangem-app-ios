//
//  KaspaTransactionHistoryProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemNetworkUtils
import TangemFoundation

final class KaspaTransactionHistoryProvider: TransactionHistoryProvider {
    private let networkProvider: TangemProvider<KaspaTransactionHistoryTarget>
    private let mapper: KaspaTransactionHistoryMapper
    private let state = OSAllocatedUnfairLock(initialState: State())

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    init(
        networkConfiguration: TangemProviderConfiguration,
        mapper: KaspaTransactionHistoryMapper
    ) {
        networkProvider = .init(configuration: networkConfiguration)
        self.mapper = mapper
    }

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
        state { !$0.hasReachedEnd }
    }

    // [REDACTED_TODO_COMMENT]
    func loadTransactionHistory(request: TransactionHistory.Request) -> AnyPublisher<TransactionHistory.Response, any Error> {
        guard case .address(let address) = request.key else {
            return .anyFail(error: TransactionHistory.ProviderError.requestKeyNotSupported)
        }

        let (resetToken, page) = state { ($0.resetToken, $0.page) }

        // if indexing is created, load the next page
        let requestPage: Int = if let page {
            page.number + 1
        } else {
            0
        }

        let limit = min(request.limit, Constants.maxPageSize)

        let target = KaspaTransactionHistoryTarget(
            type: .getCoinTransactionHistory(
                address: address,
                page: requestPage,
                limit: limit
            )
        )
        return networkProvider.requestPublisher(target)
            .filterSuccessfulStatusAndRedirectCodes()
            .map([KaspaTransactionHistoryResponse.Transaction].self, using: decoder)
            .eraseError()
            .withWeakCaptureOf(self)
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

                    state.page = TransactionHistoryIndexPage(number: requestPage)
                    state.hasReachedEnd = result.count < limit
                }

                return TransactionHistory.Response(records: transactionRecords)
            }
            .eraseToAnyPublisher()
    }

    func reset() {
        state { $0 = State() }
    }
}

// MARK: - Auxiliary types

private extension KaspaTransactionHistoryProvider {
    struct State {
        /// Changes with every reset, so a response to a request made before the reset can't update the new state.
        let resetToken = UUID()
        var page: TransactionHistoryIndexPage?
        var hasReachedEnd = false
    }
}

extension KaspaTransactionHistoryProvider {
    enum Constants {
        static let maxPageSize: Int = 50 // kaspa api limit
    }
}
