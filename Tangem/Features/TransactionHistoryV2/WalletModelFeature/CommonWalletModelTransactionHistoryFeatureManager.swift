//
//  CommonWalletModelTransactionHistoryFeatureManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

final class CommonWalletModelTransactionHistoryFeatureManager {
    private let key: TransactionHistoryProviderKey
    private let tokenItem: TokenItem
    private let registry: any TransactionHistoryProviderRegistry

    private var isAvailable: Bool {
        // [REDACTED_TODO_COMMENT]
        FeatureProvider.isAvailable(.transactionHistoryV2)
    }

    init(
        key: TransactionHistoryProviderKey,
        tokenItem: TokenItem,
        registry: any TransactionHistoryProviderRegistry
    ) {
        self.key = key
        self.tokenItem = tokenItem
        self.registry = registry
    }

    // MARK: - Feature

    var transactionHistoryProvider: (any TransactionHistorySyncing)? {
        guard isAvailable else {
            return nil
        }

        return registry.provider(for: key)
    }

    var transactionHistoryProviderPublisher: AnyPublisher<(any TransactionHistorySyncing)?, Never> {
        Just(transactionHistoryProvider).eraseToAnyPublisher()
    }
}
