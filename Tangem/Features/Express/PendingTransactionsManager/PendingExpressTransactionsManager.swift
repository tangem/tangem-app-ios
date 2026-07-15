//
//  PendingExpressTransactionsManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemExpress
import TangemFoundation

protocol PendingExpressTransactionsManager: AnyObject {
    var pendingTransactions: [PendingTransaction] { get }
    var pendingTransactionsPublisher: AnyPublisher<[PendingTransaction], Never> { get }

    func hideTransaction(with id: String)
}

class CommonPendingExpressTransactionsManager {
    @Injected(\.expressPendingTransactionsRepository) private var expressPendingTransactionsRepository: ExpressPendingTransactionRepository

    private let walletModelUpdater: WalletModelUpdater?
    private let poller: any ExpressStatusPolling<ExchangeStatusPollIteration>

    private let transactionsInProgressSubject = CurrentValueSubject<[PendingExpressTransaction], Never>([])
    private var pollingSubscription: Cancellable?

    init(
        walletModelUpdater: WalletModelUpdater?,
        poller: any ExpressStatusPolling<ExchangeStatusPollIteration>
    ) {
        self.walletModelUpdater = walletModelUpdater
        self.poller = poller

        bind()
    }

    deinit {
        ExpressLogger.debug(self, "deinit")
        pollingSubscription?.cancel()
    }

    private func bind() {
        pollingSubscription = poller.subscribe { [weak self] iteration in
            guard let self else {
                return
            }

            transactionsInProgressSubject.send(iteration.displayed)

            if !iteration.changed.isEmpty {
                ExpressLogger.info("Some transactions updated state. Recording changes to repository. Number of updated transactions: \(iteration.changed.count)")
                expressPendingTransactionsRepository.updateItems(iteration.changed)
            }

            // A transaction transitioning to a done state means we have to refresh the balance
            for record in iteration.changed where record.transactionStatus.isDone {
                walletModelUpdater?.startUpdateTask(silent: true)
            }
        }
    }
}

extension CommonPendingExpressTransactionsManager: PendingExpressTransactionsManager {
    var pendingTransactions: [PendingTransaction] {
        transactionsInProgressSubject.value.map(\.pendingTransaction)
    }

    var pendingTransactionsPublisher: AnyPublisher<[PendingTransaction], Never> {
        transactionsInProgressSubject
            .map { $0.map(\.pendingTransaction) }
            .eraseToAnyPublisher()
    }

    func hideTransaction(with id: String) {
        ExpressLogger.info("Hide transaction in the repository. Transaction id: \(id)")
        expressPendingTransactionsRepository.hideSwapTransaction(with: id)
    }
}

// MARK: - CustomStringConvertible protocol conformance

extension CommonPendingExpressTransactionsManager: CustomStringConvertible {
    var description: String {
        objectDescription(self)
    }
}
