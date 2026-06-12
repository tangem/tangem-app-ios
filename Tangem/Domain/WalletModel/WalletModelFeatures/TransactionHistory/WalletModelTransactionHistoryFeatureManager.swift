//
//  WalletModelTransactionHistoryFeatureManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemFoundation

final class WalletModelTransactionHistoryFeatureManager {
    private let key: TransactionHistoryProviderKey
    private let tokenItem: TokenItem
    private let registry: TransactionHistoryProviderRegistry
    private let transactionHistoryProviderSubject = CurrentValueSubject<TransactionHistoryProviding?, Never>(nil)
    private var transactionHistoryProviderSubscription: AnyCancellable?

    private var isFeatureAvailable: Bool {
        FeatureProvider.isAvailable(.transactionHistoryV2)
    }

    private var isBlockchainSupported: Bool {
        // [REDACTED_TODO_COMMENT]
        switch tokenItem.blockchain {
        case .solana,
             _ where tokenItem.blockchain.isEvm:
            return true
        default:
            return false
        }
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
        if isFeatureAvailable, isBlockchainSupported {
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

extension WalletModelTransactionHistoryFeatureManager: WalletModelFeatureManager {
    var featurePayload: TransactionHistoryProviding? { transactionHistoryProviderSubject.value }

    var featurePayloadPublisher: AnyPublisher<TransactionHistoryProviding?, Never> {
        transactionHistoryProviderSubject.eraseToAnyPublisher()
    }
}
