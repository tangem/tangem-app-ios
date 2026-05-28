//
//  CommonTransactionHistoryProviderRegistry.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemExpress
import TangemFoundation

/// DI registry and factory for transaction history providers, single instance per user wallet model.
/// Transaction history providers are keyed by `TransactionHistoryProviderKey`.
actor CommonTransactionHistoryProviderRegistry {
    private let cachingExpressAPIProviderFactory: CachingExpressAPIProviderFactory
    private let userWalletId: UserWalletId
    private let walletInfo: WalletInfo

    private var providers: [TransactionHistoryProviderKey: TransactionHistoryProvider] = [:]
    private var walletModelsSubscription: AnyCancellable?

    init(
        cachingExpressAPIProviderFactory: CachingExpressAPIProviderFactory,
        userWalletId: UserWalletId,
        walletInfo: WalletInfo
    ) {
        self.cachingExpressAPIProviderFactory = cachingExpressAPIProviderFactory
        self.userWalletId = userWalletId
        self.walletInfo = walletInfo
    }

    func setup(with accountModelsManager: some AccountModelsManager) async {
        walletModelsSubscription = AccountWalletModelsAggregator
            .walletModelsPublisher(from: accountModelsManager)
            .withWeakCaptureOf(self)
            .sink { registry, walletModels in
                runTask(in: registry) { registry in
                    await registry.purgeRegistry(using: walletModels)
                }
            }
    }

    private func purgeRegistry(using walletModels: [any WalletModel]) {
        let actualKeys = walletModels
            .map { TransactionHistoryProviderKey(address: $0.defaultAddressString) }
            .toSet()

        providers = providers.filter { actualKeys.contains($0.key) }
    }

    private func makeProvider(for key: TransactionHistoryProviderKey) -> TransactionHistoryProvider {
        let apiProvider = cachingExpressAPIProviderFactory.provider(
            for: userWalletId.stringValue,
            refcode: walletInfo.refcodeProvider?.getRefcode()
        )

        let exchangeStorage = InMemoryTransactionHistoryRecordsStorage<ExchangeHistoryRecord>()
        let onrampStorage = InMemoryTransactionHistoryRecordsStorage<OnrampHistoryRecord>()

        let exchangeNetworkService = TransactionHistoryNetworkServiceFactory.makeExchangeService(
            apiProvider: apiProvider,
            walletAddress: key.address,
            pageSize: Constants.pageSize
        )
        let onrampNetworkService = TransactionHistoryNetworkServiceFactory.makeOnrampService(
            apiProvider: apiProvider,
            walletAddress: key.address,
            pageSize: Constants.pageSize
        )

        let repository = CommonTransactionHistoryRepository(
            exchangeStorage: exchangeStorage,
            onrampStorage: onrampStorage,
            exchangeNetworkService: exchangeNetworkService,
            onrampNetworkService: onrampNetworkService
        )

        return TransactionHistoryProvider(repository: repository)
    }
}

// MARK: - TransactionHistoryProviderRegistry protocol conformance

extension CommonTransactionHistoryProviderRegistry: TransactionHistoryProviderRegistry {
    func provider(for key: TransactionHistoryProviderKey) -> TransactionHistorySyncing {
        if let existing = providers[key] {
            return existing
        }

        let new = makeProvider(for: key)
        providers[key] = new

        return new
    }
}

// MARK: - Constants

private extension CommonTransactionHistoryProviderRegistry {
    enum Constants {
        // [REDACTED_TODO_COMMENT]
        static let pageSize = 100
    }
}

// MARK: - Convenience extensions

extension CommonTransactionHistoryProviderRegistry {
    nonisolated func setup(with accountModelsManager: some AccountModelsManager) {
        runTask(in: self) { registry in
            await registry.setup(with: accountModelsManager)
        }
    }
}
