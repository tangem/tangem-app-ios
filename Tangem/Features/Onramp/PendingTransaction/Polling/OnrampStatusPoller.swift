//
//  OnrampStatusPoller.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemExpress
import TangemFoundation

final class OnrampStatusPoller {
    @Injected(\.onrampPendingTransactionsRepository) private var onrampPendingTransactionsRepository: OnrampPendingTransactionRepository
    @Injected(\.pendingExpressTransactionAnalyticsTracker) private var pendingExpressTransactionAnalyticsTracker: PendingExpressTransactionAnalyticsTracker

    private let userWalletId: UserWalletId
    private let tokenItem: TokenItem
    private let expressAPIProvider: ExpressAPIProvider

    private let pendingOnrampTransactionFactory = PendingOnrampTransactionFactory()
    private let subscribers = MulticastObserversHelper<OnrampStatusPollIteration>()

    /// Initialized in `init` rather than declared `lazy`: the lazy-var path raced when `pollingInitiatingTask` and
    /// `pollingResultTask` touched it concurrently on first access, producing two `PollingService` actor instances
    /// and split-brain polling state.
    private var pollingService: PollingService<PendingOnrampTransaction, OnrampPollResponse>?

    private let terminalTransactionsStorage = TerminalTransactionsStorage()
    private var pollingInitiatingTask: Task<Void, Never>?
    private var pollingResultTask: Task<Void, Never>?

    init(
        userWalletId: UserWalletId,
        tokenItem: TokenItem,
        expressAPIProvider: ExpressAPIProvider
    ) {
        self.userWalletId = userWalletId
        self.tokenItem = tokenItem
        self.expressAPIProvider = expressAPIProvider

        pollingService = PollingService(
            request: { [weak self] pendingTransaction in
                await self?.request(pendingTransaction: pendingTransaction)
            },
            shouldStopPolling: { $0.pending.transactionRecord.transactionStatus.isTerminated(branch: .onramp) },
            hasChanges: { $0.pending.transactionRecord.transactionStatus != $1.pending.transactionRecord.transactionStatus },
            pollingInterval: Constants.statusUpdateTimeout,
            maxConcurrentRequests: 3
        )

        bind()
    }

    deinit {
        if let pollingService {
            runTask(in: pollingService) {
                await $0.cancelTask()
            }
        }

        pollingInitiatingTask?.cancel()
        pollingInitiatingTask = nil

        pollingResultTask?.cancel()
        pollingResultTask = nil
    }

    private func request(pendingTransaction: PendingOnrampTransaction) async -> OnrampPollResponse? {
        do {
            let record = pendingTransaction.transactionRecord
            let onrampTransaction = try await expressAPIProvider.onrampStatus(transactionId: record.expressTransactionId)
            let pendingTransaction = pendingOnrampTransactionFactory.buildPendingOnrampTransaction(
                currentOnrampTransaction: onrampTransaction,
                for: record
            )

            await pendingExpressTransactionAnalyticsTracker.trackStatusForOnrampTransaction(
                transactionId: pendingTransaction.transactionRecord.expressTransactionId,
                tokenSymbol: tokenItem.currencySymbol,
                currencySymbol: pendingTransaction.transactionRecord.fromCurrencyCode,
                status: pendingTransaction.transactionRecord.transactionStatus,
                provider: pendingTransaction.transactionRecord.provider
            )

            return OnrampPollResponse(pending: pendingTransaction, raw: onrampTransaction)
        } catch {
            return nil
        }
    }

    private func bind() {
        let previousAndCurrentRequestsPublisher = onrampPendingTransactionsRepository
            .transactionsPublisher
            .withWeakCaptureOf(self)
            .map { poller, txRecords in
                poller.filterRelatedTokenTransactions(list: txRecords)
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

                let nonTerminalTransactions = current.filter { !$0.transactionRecord.transactionStatus.isTerminated(branch: .onramp) }
                let terminalTransactions = current.filter { $0.transactionRecord.transactionStatus.isTerminated(branch: .onramp) }
                await terminalTransactionsStorage.performIsolated { $0.transactions = terminalTransactions }

                let previousIds = previous?.uniqueProperties(\.id) ?? []
                let currentIds = current.uniqueProperties(\.id)
                let shouldForceReload = previousIds != currentIds
                await pollingService?.startPolling(requests: nonTerminalTransactions, force: shouldForceReload)

                // If there are no transactions to poll, broadcast terminal-only or empty
                if nonTerminalTransactions.isEmpty {
                    subscribers.broadcast(
                        OnrampStatusPollIteration(displayed: terminalTransactions, changed: [], polled: [])
                    )
                }
            }
        }

        pollingResultTask = runTask { [weak self] in
            guard let pollingService = self?.pollingService else { return }
            let stream = await pollingService.resultStream
            for await responses in stream {
                guard let self else { return }

                let polledTransactions = responses.map(\.data.pending)
                let rawTransactions = responses.map(\.data.raw)
                let terminalTransactions = await terminalTransactionsStorage.transactions
                let allTransactions = (polledTransactions + terminalTransactions).sorted(by: \.transactionRecord.date)
                let transactionsToUpdateInRepository = responses.compactMap { response in
                    response.hasChanges ? response.data.pending.transactionRecord : nil
                }

                subscribers.broadcast(
                    OnrampStatusPollIteration(
                        displayed: allTransactions,
                        changed: transactionsToUpdateInRepository,
                        polled: rawTransactions
                    )
                )
            }
        }
    }

    private func filterRelatedTokenTransactions(list: [OnrampPendingTransactionRecord]) -> [OnrampPendingTransactionRecord] {
        return list.filter { record in
            guard !record.isHidden, record.userWalletId == userWalletId.stringValue else {
                return false
            }
            return record.destinationTokenTxInfo.tokenItem == tokenItem
        }
    }
}

// MARK: - ExpressStatusPolling protocol conformance

extension OnrampStatusPoller: ExpressStatusPolling {
    @discardableResult
    func subscribe(_ handler: @escaping (OnrampStatusPollIteration) -> Void) -> Cancellable {
        subscribers.subscribe(handler)
    }
}

// MARK: - Constants

private extension OnrampStatusPoller {
    enum Constants {
        static let statusUpdateTimeout: TimeInterval = 10
    }
}

// MARK: - Auxiliary types

private extension OnrampStatusPoller {
    struct OnrampPollResponse: Identifiable {
        let pending: PendingOnrampTransaction
        let raw: OnrampTransaction

        var id: String {
            pending.id
        }
    }

    private actor TerminalTransactionsStorage {
        var transactions: [PendingOnrampTransaction] = []
    }
}
