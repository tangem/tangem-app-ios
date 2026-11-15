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
    private let isSafe: Bool
    private let transactionHistoryProviderSubject = CurrentValueSubject<(any TransactionHistoryProviding)?, Never>(nil)
    private var transactionHistoryProviderSubscription: AnyCancellable?

    private var isExpressSupported: Bool {
        expressAvailabilityProvider.canSwap(tokenItem: tokenItem) || expressAvailabilityProvider.canOnramp(tokenItem: tokenItem)
    }

    private var isTransactionHistorySupported: Bool {
        isExpressSupported || (isSafe && providerResolver.isJointAccountsAvailable)
    }

    init(
        providerResolver: TransactionHistoryProviderResolver,
        tokenItem: TokenItem,
        isSafe: Bool
    ) {
        self.providerResolver = providerResolver
        self.tokenItem = tokenItem
        self.isSafe = isSafe

        bind()
    }

    private func bind() {
        transactionHistoryProviderSubscription = expressAvailabilityProvider
            .availabilityDidChangePublisher
            .withWeakCaptureOf(self)
            .map(\.0.isTransactionHistorySupported)
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .asyncMap { manager, isTransactionHistorySupported in
                isTransactionHistorySupported ? await manager.providerResolver.provider() : nil
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
