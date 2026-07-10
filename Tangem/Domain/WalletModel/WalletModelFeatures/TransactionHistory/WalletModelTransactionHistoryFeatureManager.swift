//
//  WalletModelTransactionHistoryFeatureManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import TangemFoundation

final class WalletModelTransactionHistoryFeatureManager {
    @Injected(\.expressAvailabilityProvider) private var expressAvailabilityProvider: ExpressAvailabilityProvider

    private let key: TransactionHistoryProviderKey
    private let tokenItem: TokenItem
    private let registry: TransactionHistoryProviderRegistry
    private let transactionHistoryProviderSubject = CurrentValueSubject<(any TransactionHistoryProviding)?, Never>(nil)
    private var transactionHistoryProviderSubscription: AnyCancellable?

    private var isFeatureAvailable: Bool {
        FeatureProvider.isAvailable(.transactionHistoryV2)
    }

    private var isExpressSupported: Bool {
        expressAvailabilityProvider.canSwap(tokenItem: tokenItem) || expressAvailabilityProvider.canOnramp(tokenItem: tokenItem)
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
        guard isFeatureAvailable else {
            return
        }

        transactionHistoryProviderSubscription = expressAvailabilityProvider
            .availabilityDidChangePublisher
            .withWeakCaptureOf(self)
            .map(\.0.isExpressSupported)
            .removeDuplicates()
            .flatMapLatest { [registry, key] isExpressSupported -> AnyPublisher<(any TransactionHistoryProviding)?, Never> in
                guard isExpressSupported else {
                    return .just(output: nil)
                }

                return Future
                    .async { await registry.provider(for: key) }
                    .eraseToOptional()
                    .eraseToAnyPublisher()
            }
            .withWeakCaptureOf(self)
            .sink { manager, provider in
                manager.transactionHistoryProviderSubject.send(provider)
            }
    }
}

// MARK: - WalletModelFeatureManager protocol conformance

extension WalletModelTransactionHistoryFeatureManager: WalletModelFeatureManager {
    var featurePayload: (any TransactionHistoryProviding)? { transactionHistoryProviderSubject.value }

    var featurePayloadPublisher: AnyPublisher<(any TransactionHistoryProviding)?, Never> {
        transactionHistoryProviderSubject.eraseToAnyPublisher()
    }
}
