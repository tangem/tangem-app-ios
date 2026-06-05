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
            cursorStorage: InMemoryTransactionHistoryCursorStorage(),
            initialPageFetcher: { apiProvider, cursor in
                let page = try await apiProvider.exchangeHistory(
                    walletAddress: walletAddress,
                    cursor: cursor as? String,
                    limit: pageSize
                )

                return .init(records: page.records, nextCursor: page.nextCursor, hasMore: page.hasMore)
            },
            deltaPageFetcher: { apiProvider, cursor in
                let page = try await apiProvider.exchangeHistoryDelta(
                    walletAddress: walletAddress,
                    cursor: cursor as? String,
                    limit: pageSize
                )

                return .init(records: page.records, nextCursor: page.nextCursor, hasMore: page.hasMore)
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
            cursorStorage: InMemoryTransactionHistoryCursorStorage(),
            initialPageFetcher: { apiProvider, cursor in
                let page = try await apiProvider.onrampHistory(
                    walletAddress: walletAddress,
                    cursor: cursor as? String,
                    limit: pageSize
                )

                return .init(records: page.records, nextCursor: page.nextCursor, hasMore: page.hasMore)
            },
            deltaPageFetcher: { apiProvider, cursor in
                let page = try await apiProvider.onrampHistoryDelta(
                    walletAddress: walletAddress,
                    cursor: cursor as? String,
                    limit: pageSize
                )

                return .init(records: page.records, nextCursor: page.nextCursor, hasMore: page.hasMore)
            }
        )
    }
}
