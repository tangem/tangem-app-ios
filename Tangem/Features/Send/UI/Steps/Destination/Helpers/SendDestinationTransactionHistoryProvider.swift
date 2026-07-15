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
    var transactionHistoryPublisher: AnyPublisher<[SendDestinationSuggestedTransactionRecord], Never> { get }

    func preloadTransactionHistoryIfNeeded()
}

class EmptySendDestinationTransactionHistoryProvider: SendDestinationTransactionHistoryProvider {
    var transactionHistoryPublisher: AnyPublisher<[SendDestinationSuggestedTransactionRecord], Never> { .just(output: []) }
    func preloadTransactionHistoryIfNeeded() {}
}

class CommonSendDestinationTransactionHistoryProvider {
    private let transactionHistoryUpdater: any WalletModelUpdater & WalletModelTransactionHistoryProvider
    private let transactionHistoryMapper: TransactionHistoryMapper

    private var transactionHistorySubscription: AnyCancellable?

    init(
        transactionHistoryUpdater: any WalletModelUpdater & WalletModelTransactionHistoryProvider,
        transactionHistoryMapper: TransactionHistoryMapper
    ) {
        self.transactionHistoryUpdater = transactionHistoryUpdater
        self.transactionHistoryMapper = transactionHistoryMapper
    }
}

extension CommonSendDestinationTransactionHistoryProvider: SendDestinationTransactionHistoryProvider {
    var transactionHistoryPublisher: AnyPublisher<[SendDestinationSuggestedTransactionRecord], Never> {
        transactionHistoryUpdater.transactionHistoryPublisher
            .receiveOnGlobal()
            .withWeakCaptureOf(self)
            .map { provider, state in
                guard case .loaded(let items) = state else {
                    return []
                }

                return items
                    .compactMap { provider.transactionHistoryMapper.mapSuggestedRecord($0) }
                    .prefix(Constants.numberOfRecentTransactions)
                    .sorted { $0.date > $1.date }
            }
            .eraseToAnyPublisher()
    }

    func preloadTransactionHistoryIfNeeded() {
        transactionHistorySubscription = transactionHistoryUpdater
            .transactionHistoryPublisher
            .prefix(1) // We only care about the most recent state and we process it only once
            .withWeakCaptureOf(self)
            .sink { provider, transactionHistoryState in
                switch transactionHistoryState {
                case .notSupported, .loading, .loaded:
                    break
                case .notLoaded, .error:
                    Task { await provider.transactionHistoryUpdater.updateTransactionHistory() }
                }
            }
    }
}

// MARK: - Private

private extension CommonSendDestinationTransactionHistoryProvider {
    enum Constants {
        static let numberOfRecentTransactions = 10
    }
}
