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
                try await apiProvider.exchangeHistory(
                    item: .init(walletAddress: walletAddress, cursor: cursor, limit: pageSize)
                )
            },
            deltaPageFetcher: { apiProvider, cursor in
                try await apiProvider.exchangeHistoryDelta(
                    item: .init(walletAddress: walletAddress, cursor: cursor, limit: pageSize)
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
                try await apiProvider.onrampHistory(
                    item: .init(walletAddress: walletAddress, cursor: cursor, limit: pageSize)
                )
            },
            deltaPageFetcher: { apiProvider, cursor in
                try await apiProvider.onrampHistoryDelta(
                    item: .init(walletAddress: walletAddress, cursor: cursor, limit: pageSize)
                )
            }
        )
    }
}
