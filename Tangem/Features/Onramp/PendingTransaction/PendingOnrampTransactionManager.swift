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
    @Injected(\.pendingExpressTransactionAnalyticsTracker) private var pendingExpressTransactionAnalyticsTracker: PendingExpressTransactionAnalyticsTracker

    private let userWalletId: String
    private let tokenItem: TokenItem
    private let expressAPIProvider: ExpressAPIProvider
    private let unknownStatusRecoveryService: OnrampUnknownStatusRecoveryService

    private let pendingOnrampTransactionFactory = PendingOnrampTransactionFactory()

    /// Initialized in `init` rather than declared `lazy`: the lazy-var path raced when `pollingInitiatingTask` and
    /// `pollingResultTask` touched it concurrently on first access, producing two `PollingService` actor instances
    /// and split-brain polling state.
    private var pollingService: PollingService<PendingOnrampTransaction, PendingOnrampTransaction>?

    private let pendingTransactionsSubject = CurrentValueSubject<[PendingOnrampTransaction], Never>([])

    private let terminalTransactionsStorage = TerminalTransactionsStorage()
    private var pollingInitiatingTask: Task<Void, Never>?
    private var pollingResultTask: Task<Void, Never>?

    init(
        userWalletId: String,
        tokenItem: TokenItem,
        expressAPIProvider: ExpressAPIProvider,
        unknownStatusRecoveryService: OnrampUnknownStatusRecoveryService
    ) {
        self.userWalletId = userWalletId
        self.tokenItem = tokenItem
        self.expressAPIProvider = expressAPIProvider
        self.unknownStatusRecoveryService = unknownStatusRecoveryService

        pollingService = PollingService(
            request: { [weak self] pendingTransaction in
                await self?.request(pendingTransaction: pendingTransaction)
            },
            shouldStopPolling: { $0.transactionRecord.transactionStatus.isTerminated(branch: .onramp) },
            hasChanges: { $0.transactionRecord.transactionStatus != $1.transactionRecord.transactionStatus },
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

    private func request(pendingTransaction: PendingOnrampTransaction) async -> PendingOnrampTransaction? {
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

                let nonTerminalTransactions = current.filter { !$0.transactionRecord.transactionStatus.isTerminated(branch: .onramp) }
                let terminalTransactions = current.filter { $0.transactionRecord.transactionStatus.isTerminated(branch: .onramp) }
                await terminalTransactionsStorage.performIsolated { $0.transactions = terminalTransactions }

                let shouldForceReload = previous?.count ?? 0 != current.count
                await pollingService?.startPolling(requests: nonTerminalTransactions, force: shouldForceReload)

                // If there are no transactions to poll, send terminal-only or empty
                if nonTerminalTransactions.isEmpty {
                    pendingTransactionsSubject.send(terminalTransactions)
                }
            }
        }

        pollingResultTask = runTask { [weak self] in
            guard let pollingService = self?.pollingService else { return }
            let stream = await pollingService.resultStream
            for await responses in stream {
                guard let self else { return }

                let polledTransactions = responses.map(\.data)
                let terminalTransactions = await terminalTransactionsStorage.transactions
                let allTransactions = (polledTransactions + terminalTransactions).sorted(by: \.transactionRecord.date)
                let transactionsToUpdateInRepository = responses.compactMap { response in
                    response.hasChanges ? response.data.transactionRecord : nil
                }

                pendingTransactionsSubject.send(allTransactions)
                onrampPendingTransactionsRepository.updateItems(transactionsToUpdateInRepository)
            }
        }

        if FeatureProvider.isAvailable(.onrampApplePayHistoryFallback) {
            unknownStatusRecoveryService.start()
        }
    }

    private func filterRelatedTokenTransactions(list: [OnrampPendingTransactionRecord]) -> [OnrampPendingTransactionRecord] {
        return list.filter { record in
            guard !record.isHidden, record.userWalletId == userWalletId else {
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
        onrampPendingTransactionsRepository.hideOnrampTransaction(with: id)
    }
}

// MARK: - Constants

private extension CommonPendingOnrampTransactionsManager {
    enum Constants {
        static let statusUpdateTimeout: TimeInterval = 10
    }
}

// MARK: - Auxiliary types

private extension CommonPendingOnrampTransactionsManager {
    private actor TerminalTransactionsStorage {
        var transactions: [PendingOnrampTransaction] = []
    }
}
