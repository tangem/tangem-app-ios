//
//  TransactionHistoryNetworkServiceFactory.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public enum TransactionHistoryNetworkServiceFactory {
    public static func makeExchangeService(
        apiProvider: ExpressAPIProvider,
        walletAddress: String,
        pageSize: Int
    ) -> any TransactionHistoryNetworkService<ExchangeHistoryRecord> {
        CommonTransactionHistoryNetworkService(
            apiProvider: apiProvider,
            initialCursorStorage: InMemoryTransactionHistoryCursorStorage(),
            deltaCursorStorage: InMemoryTransactionHistoryCursorStorage(),
            initialPageFetcher: { apiProvider, cursor in
                let page = try await apiProvider.exchangeHistory(
                    item: .init(walletAddress: walletAddress, cursor: cursor, limit: pageSize)
                )

                return .init(
                    records: page.records,
                    nextCursor: page.nextCursor,
                    startDeltaCursor: page.startDeltaCursor,
                    hasMore: page.hasMore
                )
            },
            deltaPageFetcher: { apiProvider, cursor in
                let page = try await apiProvider.exchangeHistoryDelta(
                    item: .init(walletAddress: walletAddress, cursor: cursor, limit: pageSize)
                )

                return .init(
                    records: page.records,
                    nextCursor: page.nextCursor,
                    startDeltaCursor: nil,
                    hasMore: page.hasMore
                )
            }
        )
    }

    public static func makeOnrampService(
        apiProvider: ExpressAPIProvider,
        walletAddress: String,
        pageSize: Int
    ) -> any TransactionHistoryNetworkService<OnrampHistoryRecord> {
        CommonTransactionHistoryNetworkService(
            apiProvider: apiProvider,
            initialCursorStorage: InMemoryTransactionHistoryCursorStorage(),
            deltaCursorStorage: InMemoryTransactionHistoryCursorStorage(),
            initialPageFetcher: { apiProvider, cursor in
                let page = try await apiProvider.onrampHistory(
                    item: .init(walletAddress: walletAddress, cursor: cursor, limit: pageSize)
                )

                return .init(
                    records: page.records,
                    nextCursor: page.nextCursor,
                    startDeltaCursor: page.startDeltaCursor,
                    hasMore: page.hasMore
                )
            },
            deltaPageFetcher: { apiProvider, cursor in
                let page = try await apiProvider.onrampHistoryDelta(
                    item: .init(walletAddress: walletAddress, cursor: cursor, limit: pageSize)
                )

                return .init(
                    records: page.records,
                    nextCursor: page.nextCursor,
                    startDeltaCursor: nil,
                    hasMore: page.hasMore
                )
            }
        )
    }
}
