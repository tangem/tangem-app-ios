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
import TangemFoundation

final class CommonWalletModelTransactionHistoryFeatureManager {
    private let key: TransactionHistoryProviderKey
    private let tokenItem: TokenItem
    private let registry: TransactionHistoryProviderRegistry
    private let transactionHistoryProviderSubject = CurrentValueSubject<TransactionHistorySyncing?, Never>(nil)
    private var transactionHistoryProviderSubscription: AnyCancellable?

    private var isAvailable: Bool {
        // [REDACTED_TODO_COMMENT]
        FeatureProvider.isAvailable(.transactionHistoryV2)
    }

    init(
        key: TransactionHistoryProviderKey,
        tokenItem: TokenItem,
        registry: TransactionHistoryProviderRegistry
    ) {
        self.key = key
        self.tokenItem = tokenItem
        self.registry = registry

        bind()
    }

    private func bind() {
        if isAvailable {
            transactionHistoryProviderSubscription = Future
                .async { [registry, key] in
                    await registry.provider(for: key)
                }
                .eraseToOptional()
                .sink { [transactionHistoryProviderSubject] in
                    transactionHistoryProviderSubject.send($0)
                }
        }
    }
}

// MARK: - WalletModelFeatureManager protocol conformance

extension CommonWalletModelTransactionHistoryFeatureManager: WalletModelFeatureManager {
    var featurePayload: TransactionHistorySyncing? { transactionHistoryProviderSubject.value }

    var featurePayloadPublisher: AnyPublisher<TransactionHistorySyncing?, Never> {
        transactionHistoryProviderSubject.eraseToAnyPublisher()
    }
}
