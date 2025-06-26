//
//  SendDestinationTransactionHistoryProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

protocol SendDestinationTransactionHistoryProvider {
    var transactionHistoryPublisher: AnyPublisher<[TransactionRecord], Never> { get }
    func preloadTransactionsHistoryIfNeeded()
}

class CommonSendDestinationTransactionHistoryProvider {
    private let transactionHistoryUpdater: WalletModelHistoryUpdater

    init(transactionHistoryUpdater: WalletModelHistoryUpdater) {
        self.transactionHistoryUpdater = transactionHistoryUpdater
    }
}

extension CommonSendDestinationTransactionHistoryProvider: SendDestinationTransactionHistoryProvider {
    var transactionHistoryPublisher: AnyPublisher<[TransactionRecord], Never> {
        transactionHistoryUpdater.transactionHistoryPublisher.map { state in
            guard case .loaded(let items) = state else {
                return []
            }

            return items
        }
        .eraseToAnyPublisher()
    }

    func preloadTransactionsHistoryIfNeeded() {
        var subscription: AnyCancellable?
        subscription = transactionHistoryUpdater
            .transactionHistoryPublisher
            .prefix(1) // We only care about the most recent state and we process it only once
            .flatMap { [transactionHistoryUpdater] transactionHistoryState in
                switch transactionHistoryState {
                case .notSupported,
                     .loading,
                     .loaded:
                    return AnyPublisher.just
                case .notLoaded, .error:
                    return transactionHistoryUpdater.updateTransactionsHistory()
                }
            }
            .sink { withExtendedLifetime(subscription) {} }
    }
}
