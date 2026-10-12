//
//  UserWalletTransactionHistoryProviderFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress
import TangemFoundation

enum UserWalletTransactionHistoryProviderFactory {
    // [REDACTED_TODO_COMMENT]
    private static let pageSize = 100

    static func makeProvider(
        cachingExpressAPIProviderFactory: CachingExpressAPIProviderFactory,
        userWalletId: UserWalletId,
        walletInfo: WalletInfo
    ) -> TransactionHistoryWalletSyncService {
        let apiProviderFactory: @Sendable () -> ExpressAPIProvider = {
            cachingExpressAPIProviderFactory.provider(
                for: userWalletId.stringValue,
                refcode: walletInfo.refcodeProvider?.getRefcode()
            )
        }

        let syncMetadataStorage = CommonTransactionHistorySyncMetadataStorage(userWalletId: userWalletId)
        let writer = CommonTransactionHistoryRecordsWriter()

        let exchangeNetworkService = TransactionHistoryNetworkServiceFactory.makeExchangeService(
            apiProviderFactory: apiProviderFactory,
            syncMetadataStorage: syncMetadataStorage,
            pageSize: pageSize
        )
        let onrampNetworkService = TransactionHistoryNetworkServiceFactory.makeOnrampService(
            apiProviderFactory: apiProviderFactory,
            syncMetadataStorage: syncMetadataStorage,
            pageSize: pageSize
        )

        let repository = CommonTransactionHistoryRepository(
            reader: CommonTransactionHistoryRecordsReader(),
            writer: writer,
            exchangeNetworkService: exchangeNetworkService,
            onrampNetworkService: onrampNetworkService
        )

        return TransactionHistoryWalletSyncService(
            repository: repository,
            syncMetadataStorage: syncMetadataStorage,
            userWalletId: userWalletId
        )
    }
}
