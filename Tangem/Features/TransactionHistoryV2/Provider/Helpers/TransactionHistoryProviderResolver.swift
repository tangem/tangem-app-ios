//
//  TransactionHistoryProviderResolver.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress
import TangemFoundation

/// Lazily creates the single transaction history provider of a user wallet and shares it with all of its wallet models.
actor TransactionHistoryProviderResolver {
    private let userWalletId: UserWalletId
    private let refcodeProvider: RefcodeProvider?
    private var cachedProvider: (any TransactionHistoryProviding)?

    init(
        userWalletId: UserWalletId,
        refcodeProvider: RefcodeProvider?
    ) {
        self.userWalletId = userWalletId
        self.refcodeProvider = refcodeProvider
    }

    func provider() -> any TransactionHistoryProviding {
        if let cachedProvider {
            return cachedProvider
        }

        let provider = makeProvider()
        cachedProvider = provider

        return provider
    }

    private func makeProvider() -> any TransactionHistoryProviding {
        let cachingExpressAPIProviderFactory = CachingExpressAPIProviderFactory { userWalletId, refcode in
            ExpressAPIProviderFactory().makeExpressAPIProvider(userId: userWalletId, refcode: refcode)
        }

        let apiProviderFactory: TransactionHistoryAPIProviderFactory = { [userWalletId, refcodeProvider] in
            cachingExpressAPIProviderFactory.provider(
                for: userWalletId.stringValue,
                refcode: refcodeProvider?.getRefcode()
            )
        }

        let syncMetadataStorage = CommonTransactionHistorySyncMetadataStorage(userWalletId: userWalletId)

        let exchangeNetworkService = TransactionHistoryNetworkServiceFactory.makeExchangeService(
            apiProviderFactory: apiProviderFactory,
            syncMetadataStorage: syncMetadataStorage,
            pageSize: Constants.pageSize
        )
        let onrampNetworkService = TransactionHistoryNetworkServiceFactory.makeOnrampService(
            apiProviderFactory: apiProviderFactory,
            syncMetadataStorage: syncMetadataStorage,
            pageSize: Constants.pageSize
        )

        let repository = CommonTransactionHistoryRepository(
            reader: CommonTransactionHistoryRecordsReader(),
            writer: CommonTransactionHistoryRecordsWriter(),
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

// MARK: - Constants

private extension TransactionHistoryProviderResolver {
    enum Constants {
        // [REDACTED_TODO_COMMENT]
        static let pageSize = 100
    }
}
