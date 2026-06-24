//
//  PendingOnrampTransactionManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemExpress
import TangemFoundation

class CommonPendingOnrampTransactionsManager {
    @Injected(\.onrampPendingTransactionsRepository) private var onrampPendingTransactionsRepository: OnrampPendingTransactionRepository

    private let unknownStatusRecoveryService: OnrampUnknownStatusRecoveryService
    private let poller: any ExpressStatusPolling<OnrampStatusPollIteration>

    private let pendingTransactionsSubject = CurrentValueSubject<[PendingOnrampTransaction], Never>([])
    private var pollingSubscription: Cancellable?

    init(
        unknownStatusRecoveryService: OnrampUnknownStatusRecoveryService,
        poller: any ExpressStatusPolling<OnrampStatusPollIteration>
    ) {
        self.unknownStatusRecoveryService = unknownStatusRecoveryService
        self.poller = poller

        bind()
    }

    deinit {
        pollingSubscription?.cancel()
    }

    private func bind() {
        pollingSubscription = poller.subscribe { [weak self] iteration in
            guard let self else {
                return
            }

            pendingTransactionsSubject.send(iteration.displayed)
            onrampPendingTransactionsRepository.updateItems(iteration.changed)
        }

        if FeatureProvider.isAvailable(.onrampApplePayHistoryFallback) {
            unknownStatusRecoveryService.start()
        }
    }
}

// MARK: - PendingExpressTransactionsManager

extension CommonPendingOnrampTransactionsManager: PendingExpressTransactionsManager {
    var pendingTransactions: [PendingTransaction] {
        pendingTransactionsSubject.value.map(\.pendingTransaction)
    }

    var pendingTransactionsPublisher: AnyPublisher<[PendingTransaction], Never> {
        pendingTransactionsSubject
            .map { $0.map(\.pendingTransaction) }
            .eraseToAnyPublisher()
    }

    func hideTransaction(with id: String) {
        onrampPendingTransactionsRepository.hideSwapTransaction(with: id)
    }
}
