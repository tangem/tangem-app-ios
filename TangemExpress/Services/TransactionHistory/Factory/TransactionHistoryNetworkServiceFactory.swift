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
        syncMetadataStorage: TransactionHistorySyncMetadataStorage,
        walletAddress: String,
        pageSize: Int
    ) -> any TransactionHistoryNetworkService<ExchangeTransaction> {
        let initialCursorStorageAdapter = TransactionHistorySyncMetadataCursorStorageAdapter(
            metadataStorage: syncMetadataStorage,
            branch: .swap,
            cursorKind: .initialSync
        )
        let deltaCursorStorageAdapter = TransactionHistorySyncMetadataCursorStorageAdapter(
            metadataStorage: syncMetadataStorage,
            branch: .swap,
            cursorKind: .deltaSync
        )

        return CommonTransactionHistoryNetworkService(
            apiProvider: apiProvider,
            initialCursorStorage: initialCursorStorageAdapter,
            deltaCursorStorage: deltaCursorStorageAdapter,
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
        syncMetadataStorage: TransactionHistorySyncMetadataStorage,
        walletAddress: String,
        pageSize: Int
    ) -> any TransactionHistoryNetworkService<OnrampTransaction> {
        let initialCursorStorageAdapter = TransactionHistorySyncMetadataCursorStorageAdapter(
            metadataStorage: syncMetadataStorage,
            branch: .onramp,
            cursorKind: .initialSync
        )
        let deltaCursorStorageAdapter = TransactionHistorySyncMetadataCursorStorageAdapter(
            metadataStorage: syncMetadataStorage,
            branch: .onramp,
            cursorKind: .deltaSync
        )

        return CommonTransactionHistoryNetworkService(
            apiProvider: apiProvider,
            initialCursorStorage: initialCursorStorageAdapter,
            deltaCursorStorage: deltaCursorStorageAdapter,
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
