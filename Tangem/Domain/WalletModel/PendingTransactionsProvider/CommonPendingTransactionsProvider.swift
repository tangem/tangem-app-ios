//
//  CommonPendingTransactionsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemFoundation

final class CommonPendingTransactionsProvider {
    private let walletProvider: WalletProvider
    private let tokenItem: TokenItem
    private let blockingPolicy = PendingTransactionsBlockingPolicy()
    private let hasJointOperationsInFlightSubject = CurrentValueSubject<Bool, Never>(false)
    private var jointOperationsSubscription: AnyCancellable?

    init(walletProvider: WalletProvider, tokenItem: TokenItem) {
        self.walletProvider = walletProvider
        self.tokenItem = tokenItem
    }
}

// MARK: - PendingTransactionsProvider

extension CommonPendingTransactionsProvider: PendingTransactionsProvider {
    func setCryptoAccount(_ cryptoAccount: any CryptoAccountModel) {
        guard let jointAccount = cryptoAccount as? any JointAccountModel else {
            jointOperationsSubscription = nil
            hasJointOperationsInFlightSubject.send(false)
            return
        }

        let blockchain = tokenItem.blockchain

        jointOperationsSubscription = jointAccount
            .jointAccountPendingOperationsProvider
            .pendingOperationsPublisher
            .map { operations in
                operations.contains { $0.tokenItem.blockchain == blockchain && $0.status.isInFlight }
            }
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { provider, hasOperations in
                provider.hasJointOperationsInFlightSubject.send(hasOperations)
            }
    }

    var pendingTransactions: [PendingTransactionRecord] {
        filterOwn(walletProvider.wallet.pendingTransactions)
    }

    var pendingTransactionsPublisher: AnyPublisher<[PendingTransactionRecord], Never> {
        walletProvider.walletPublisher
            .withWeakCaptureOf(self)
            .map { $0.filterOwn($1.pendingTransactions) }
            .eraseToAnyPublisher()
    }

    var hasBlockingPendingTransactions: Bool {
        hasBlockingTransactions(for: tokenItem.amountType)
    }

    var hasAnyBlockingPendingTransactions: Bool {
        hasBlockingTransactions(for: nil)
    }

    var hasAnyBlockingPendingTransactionsPublisher: AnyPublisher<Bool, Never> {
        hasBlockingTransactionsPublisher(for: nil)
    }
}

// MARK: - Private

private extension CommonPendingTransactionsProvider {
    func filterOwn(_ pendingTransactions: [PendingTransactionRecord]) -> [PendingTransactionRecord] {
        let amountType = tokenItem.amountType
        return pendingTransactions.filter { !$0.isDummy && $0.amount.type == amountType }
    }

    func hasBlockingTransactions(for amountType: Amount.AmountType?) -> Bool {
        if hasJointOperationsInFlightSubject.value {
            return true
        }

        return blockingPolicy.hasBlockingTransactions(
            in: walletProvider.wallet.pendingTransactions,
            blockchain: tokenItem.blockchain,
            amountType: amountType
        )
    }

    func hasBlockingTransactionsPublisher(for amountType: Amount.AmountType?) -> AnyPublisher<Bool, Never> {
        let blockchain = tokenItem.blockchain
        let blockingPolicy = blockingPolicy

        return Publishers.CombineLatest(
            walletProvider.walletPublisher
                .map { blockingPolicy.hasBlockingTransactions(in: $0.pendingTransactions, blockchain: blockchain, amountType: amountType) },
            hasJointOperationsInFlightSubject
        )
        .map { $0 || $1 }
        .removeDuplicates()
        .eraseToAnyPublisher()
    }
}
