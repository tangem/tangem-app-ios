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
}

// MARK: - WalletModelTransactionHistoryFeatureManager protocol conformance

extension CommonWalletModelTransactionHistoryFeatureManager: WalletModelTransactionHistoryFeatureManager {
    var transactionHistoryFeature: WalletModelFeature? {
        guard isAvailable else {
            return nil
        }
        return .transactionHistory(sync: registry.sync(for: key))
    }

    var transactionHistoryFeaturePublisher: AnyPublisher<WalletModelFeature?, Never> {
        Just(transactionHistoryFeature).eraseToAnyPublisher()
    }
}
