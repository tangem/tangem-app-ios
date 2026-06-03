//
//  CommonTransactionHistoryProviderRegistry.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

/// Registry for transaction history providers, single instance per user wallet model.
/// Transaction history providers are keyed by `TransactionHistoryProviderKey`.
actor CommonTransactionHistoryProviderRegistry {
    private var providers: [TransactionHistoryProviderKey: TransactionHistoryProvider] = [:]
    private var walletModelsSubscription: AnyCancellable?

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
}

// MARK: - TransactionHistoryProviderRegistry protocol conformance

extension CommonTransactionHistoryProviderRegistry: TransactionHistoryProviderRegistry {
    func provider(for key: TransactionHistoryProviderKey) -> TransactionHistorySyncing {
        if let existing = providers[key] {
            return existing
        }

        let new = TransactionHistoryProvider()
        providers[key] = new

        return new
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
