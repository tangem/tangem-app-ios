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
    @Injected(\.pendingExpressTransactionAnalayticsTracker) private var pendingExpressTransactionAnalyticsTracker: PendingExpressTransactionAnalyticsTracker

    private let userWalletId: String
    private let tokenItem: TokenItem
    private let expressAPIProvider: ExpressAPIProvider

    private let pendingOnrampTransactionFactory = PendingOnrampTransactionFactory()

    private lazy var pollingService: PollingService<PendingOnrampTransaction, PendingOnrampTransaction> = PollingService(
        request: { [weak self] pendingTransaction in
            await self?.request(pendingTransaction: pendingTransaction)
        },
        shouldStopPolling: { $0.transactionRecord.transactionStatus.isTerminated(branch: .onramp) },
        hasChanges: { $0.transactionRecord.transactionStatus != $1.transactionRecord.transactionStatus },
        pollingInterval: Constants.statusUpdateTimeout,
        maxConcurrentRequests: 3
    )

    private let pendingTransactionsSubject = CurrentValueSubject<[PendingOnrampTransaction], Never>([])

    private let terminalTransactions = ThreadSafeContainer<[PendingOnrampTransaction]>([])
    private var pollingInitiatingTask: Task<Void, Never>?
    private var pollingResultTask: Task<Void, Never>?
    private var isPaused = false

    init(
        userWalletId: String,
        tokenItem: TokenItem,
        expressAPIProvider: ExpressAPIProvider
    ) {
        self.userWalletId = userWalletId
        self.tokenItem = tokenItem
        self.expressAPIProvider = expressAPIProvider

        bind()
    }

    deinit {
        runTask(in: pollingService) {
            await $0.cancelTask()
        }

        pollingInitiatingTask?.cancel()
        pollingInitiatingTask = nil

        pollingResultTask?.cancel()
        pollingResultTask = nil
    }

    private func request(pendingTransaction: PendingOnrampTransaction) async -> PendingOnrampTransaction? {
        do {
            let record = pendingTransaction.transactionRecord
            let onrampTransaction = try await expressAPIProvider.onrampStatus(transactionId: record.expressTransactionId)
            let pendingTransaction = pendingOnrampTransactionFactory.buildPendingOnrampTransaction(
                currentOnrampTransaction: onrampTransaction,
                for: record
            )

            pendingExpressTransactionAnalyticsTracker.trackStatusForOnrampTransaction(
                transactionId: pendingTransaction.transactionRecord.expressTransactionId,
                tokenSymbol: tokenItem.currencySymbol,
                currencySymbol: pendingTransaction.transactionRecord.fromCurrencyCode,
                status: pendingTransaction.transactionRecord.transactionStatus,
                provider: pendingTransaction.transactionRecord.provider
            )

            return pendingTransaction
        } catch {
            return nil
        }
    }

    private func bind() {
        let previousAndCurrentRequestsPublisher = onrampPendingTransactionsRepository
            .transactionsPublisher
            .withWeakCaptureOf(self)
            .map { manager, txRecords in
                manager.filterRelatedTokenTransactions(list: txRecords)
            }
            .removeDuplicates()
            .map { transactions in
                let factory = PendingOnrampTransactionFactory()
                let savedPendingTransactions = transactions.map(factory.buildPendingOnrampTransaction(for:))
                return savedPendingTransactions
            }
            .withPrevious()

        pollingInitiatingTask = runTask { [weak self] in
            let previousAndCurrentRequestsSequence = await previousAndCurrentRequestsPublisher.values

            for await previousAndCurrentRequests in previousAndCurrentRequestsSequence {
                guard let self else { return }

                let previous = previousAndCurrentRequests.previous
                let current = previousAndCurrentRequests.current

                let nonTerminal = current.filter { !$0.transactionRecord.transactionStatus.isTerminated(branch: .onramp) }
                let terminal = current.filter { $0.transactionRecord.transactionStatus.isTerminated(branch: .onramp) }
                terminalTransactions.mutate { $0 = terminal }

                if !isPaused {
                    let shouldForceReload = previous?.count ?? 0 != current.count
                    await pollingService.startPolling(requests: nonTerminal, force: shouldForceReload)
                }

                if nonTerminal.isEmpty {
                    pendingTransactionsSubject.send(terminal)
                }
            }
        }

        pollingResultTask = runTask { [weak self] in
            guard let pollingService = self?.pollingService else { return }
            let stream = await pollingService.resultStream
            for await responses in stream {
                guard let self else { return }

                let polledTransactions = responses.map(\.data)
                let allTransactions = (polledTransactions + terminalTransactions.read()).sorted(by: \.transactionRecord.date)
                let transactionsToUpdateInRepository = responses.compactMap { response in
                    response.hasChanges ? response.data.transactionRecord : nil
                }

                pendingTransactionsSubject.send(allTransactions)
                onrampPendingTransactionsRepository.updateItems(transactionsToUpdateInRepository)
            }
        }
    }

    private func filterRelatedTokenTransactions(list: [OnrampPendingTransactionRecord]) -> [OnrampPendingTransactionRecord] {
        list.filter { record in
            guard !record.isHidden else {
                return false
            }

            guard record.userWalletId == userWalletId else {
                return false
            }

            return record.destinationTokenTxInfo.tokenItem == tokenItem
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

    func pauseOnrampTransactionPolling() {
        guard !isPaused else { return }
        isPaused = true
        runTask(in: pollingService) { await $0.cancelTask() }
    }

    func resumeOnrampTransactionPolling() {
        guard isPaused else { return }
        isPaused = false

        let records = filterRelatedTokenTransactions(list: onrampPendingTransactionsRepository.transactions)
        let nonTerminal = records
            .map(pendingOnrampTransactionFactory.buildPendingOnrampTransaction(for:))
            .filter { !$0.transactionRecord.transactionStatus.isTerminated(branch: .onramp) }

        guard !nonTerminal.isEmpty else { return }

        runTask(in: pollingService) { [nonTerminal] in
            await $0.startPolling(requests: nonTerminal, force: true)
        }
    }
}

extension CommonPendingOnrampTransactionsManager {
    enum Constants {
        static let statusUpdateTimeout: Double = 10
    }
}
