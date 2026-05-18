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
    private let key: TransactionHistorySyncKey
    private let tokenItem: TokenItem
    private let registry: any TransactionHistorySyncRegistry

    private var isAvailable: Bool {
        // [REDACTED_TODO_COMMENT]
        FeatureProvider.isAvailable(.transactionHistoryV2)
    }

    init(
        key: TransactionHistorySyncKey,
        tokenItem: TokenItem,
        registry: any TransactionHistorySyncRegistry
    ) {
        self.key = key
        self.tokenItem = tokenItem
        self.registry = registry
    }

    // MARK: - Feature

    var transactionHistorySync: (any TransactionHistorySyncing)? {
        guard isAvailable else {
            return nil
        }
        return registry.sync(for: key)
    }

    var transactionHistorySyncPublisher: AnyPublisher<(any TransactionHistorySyncing)?, Never> {
        Just(transactionHistorySync).eraseToAnyPublisher()
    }
}
