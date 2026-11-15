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
    nonisolated let isJointAccountsAvailable: Bool

    private let userWalletId: UserWalletId
    private let refcodeProvider: RefcodeProvider?
    private let jointAccountsRepository: JointAccountsRepository
    private var cachedProvider: (any TransactionHistoryProviding)?
    private var cachedJointOperationsSyncService: JointOperationsHistorySyncService?

    init(
        userWalletId: UserWalletId,
        refcodeProvider: RefcodeProvider?,
        jointAccountsRepository: JointAccountsRepository,
        isJointAccountsAvailable: Bool
    ) {
        self.userWalletId = userWalletId
        self.refcodeProvider = refcodeProvider
        self.jointAccountsRepository = jointAccountsRepository
        self.isJointAccountsAvailable = isJointAccountsAvailable
    }

    func provider() -> any TransactionHistoryProviding {
        if let cachedProvider {
            return cachedProvider
        }

        let provider = makeProvider()
        cachedProvider = provider

        return provider
    }

    func jointOperationsSyncService() -> any JointOperationsHistorySyncing {
        guard isJointAccountsAvailable else {
            return MockJointOperationsHistorySyncService()
        }

        if let cachedJointOperationsSyncService {
            return cachedJointOperationsSyncService
        }

        let syncService = makeJointOperationsSyncService()
        cachedJointOperationsSyncService = syncService

        return syncService
    }

    private func makeProvider() -> any TransactionHistoryProviding {
        let expressProvider = makeExpressProvider()

        guard isJointAccountsAvailable else {
            return expressProvider
        }

        return CompositeTransactionHistoryProvider(
            expressProvider: expressProvider,
            jointOperationsSyncService: jointOperationsSyncService()
        )
    }

    private func makeExpressProvider() -> TransactionHistoryWalletSyncService {
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

    private func makeJointOperationsSyncService() -> JointOperationsHistorySyncService {
        let syncMetadataStorage = CommonJointOperationsSyncMetadataStorage(userWalletId: userWalletId)

        let networkService = CommonJointOperationsHistoryNetworkService(
            networkService: CommonJointAccountsNetworkService(userWalletId: userWalletId),
            writer: CommonJointOperationsHistoryWriter(writer: CommonTransactionHistoryRecordsWriter()),
            syncMetadataStorage: syncMetadataStorage,
            pageSize: Constants.jointOperationsPageSize
        )

        return JointOperationsHistorySyncService(
            networkService: networkService,
            syncMetadataStorage: syncMetadataStorage,
            jointAccountsRepository: jointAccountsRepository
        )
    }
}

// MARK: - JointOperationsHistoryDeltaSyncing protocol conformance

extension TransactionHistoryProviderResolver: JointOperationsHistoryDeltaSyncing {
    func syncDelta() async {
        await jointOperationsSyncService().syncDelta()
    }
}

// MARK: - Constants

private extension TransactionHistoryProviderResolver {
    enum Constants {
        // [REDACTED_TODO_COMMENT]
        static let pageSize = 100
        static let jointOperationsPageSize = 100
    }
}
