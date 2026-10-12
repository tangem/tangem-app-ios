//
//  WalletModelTransactionHistoryFeatureManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class WalletModelTransactionHistoryFeatureManager {
    @Injected(\.expressAvailabilityProvider) private var expressAvailabilityProvider: ExpressAvailabilityProvider

    private let providerResolver: TransactionHistoryProviderResolver
    private let tokenItem: TokenItem
    private let transactionHistoryProviderSubject = CurrentValueSubject<(any TransactionHistoryProviding)?, Never>(nil)
    private var transactionHistoryProviderSubscription: AnyCancellable?

    private var isFeatureAvailable: Bool {
        FeatureProvider.isAvailable(.transactionHistoryV2)
    }

    private var isExpressSupported: Bool {
        expressAvailabilityProvider.canSwap(tokenItem: tokenItem) || expressAvailabilityProvider.canOnramp(tokenItem: tokenItem)
    }

    init(
        providerResolver: TransactionHistoryProviderResolver,
        tokenItem: TokenItem
    ) {
        self.providerResolver = providerResolver
        self.tokenItem = tokenItem

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
            .withWeakCaptureOf(self)
            .asyncMap { manager, isExpressSupported in
                isExpressSupported ? await manager.providerResolver.provider() : nil
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
