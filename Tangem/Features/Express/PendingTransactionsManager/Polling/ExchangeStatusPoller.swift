//
//  ExchangeStatusPoller.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import TangemExpress
import TangemFoundation

final class ExchangeStatusPoller {
    @Injected(\.expressPendingTransactionsRepository) private var expressPendingTransactionsRepository: ExpressPendingTransactionRepository
    @Injected(\.pendingExpressTransactionAnalyticsTracker) private var pendingExpressTransactionAnalyticsTracker: PendingExpressTransactionAnalyticsTracker
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    private let userWalletId: UserWalletId
    private let tokenItem: TokenItem
    private let cachingExpressAPIProviderFactory: CachingExpressAPIProviderFactory
    private let expressRefundedTokenHandler: ExpressRefundedTokenHandler

    private let pendingTransactionFactory = PendingExpressTransactionFactory()
    private let subscribers = MulticastObserversHelper<ExchangeStatusPollIteration>()

    private var latestDisplayed: [PendingExpressTransaction] = []
    private var expressPendingTransactionsRepositorySubscription: AnyCancellable?
    private var updateTask: Task<Void, Never>?
    private var transactionsScheduledForUpdate: [PendingExpressTransaction] = []

    init(
        userWalletId: UserWalletId,
        tokenItem: TokenItem,
        cachingExpressAPIProviderFactory: CachingExpressAPIProviderFactory,
        expressRefundedTokenHandler: ExpressRefundedTokenHandler
    ) {
        self.userWalletId = userWalletId
        self.tokenItem = tokenItem
        self.cachingExpressAPIProviderFactory = cachingExpressAPIProviderFactory
        self.expressRefundedTokenHandler = expressRefundedTokenHandler

        bind()
    }

    deinit {
        ExpressLogger.debug(self, "deinit")
        cancelTask()
    }

    private func bind() {
        let transactionFactory = PendingExpressTransactionFactory()

        expressPendingTransactionsRepositorySubscription = expressPendingTransactionsRepository
            .transactionsPublisher
            .withWeakCaptureOf(self)
            .map { poller, txRecords in
                poller.filterRelatedTokenTransactions(list: txRecords)
            }
            .removeDuplicates()
            .mapMany(transactionFactory.buildPendingExpressTransaction(for:))
            .withWeakCaptureOf(self)
            .sink { poller, transactions in
                ExpressLogger.info("Receive new transactions to update: \(transactions.count). Number of already scheduled transactions: \(poller.transactionsScheduledForUpdate.count)")
                // If transactions updated their statuses only no need to cancel currently scheduled task and force reload it
                let scheduledIds = poller.transactionsScheduledForUpdate.uniqueProperties(\.transactionRecord.expressTransactionId)
                let receivedIds = transactions.uniqueProperties(\.transactionRecord.expressTransactionId)
                let shouldForceReload = scheduledIds != receivedIds
                poller.transactionsScheduledForUpdate = transactions
                poller.latestDisplayed = transactions
                poller.subscribers.broadcast(
                    ExchangeStatusPollIteration(displayed: transactions, changed: [], polled: [])
                )
                poller.updateTransactionsStatuses(forceReload: shouldForceReload)
            }
    }

    private func cancelTask() {
        ExpressLogger.info("Attempt to cancel update task")
        if updateTask != nil {
            updateTask?.cancel()
            updateTask = nil
        }
    }

    private func updateTransactionsStatuses(forceReload: Bool) {
        if !forceReload, updateTask != nil {
            ExpressLogger.info("Receive update tx status request but not force reload. Update task is still in progress. Skipping update request. Scheduled to update: \(transactionsScheduledForUpdate.count). Force reload: \(forceReload)")
            return
        }

        cancelTask()

        if transactionsScheduledForUpdate.isEmpty {
            ExpressLogger.info("No transactions scheduled for update. Skipping update request. Force reload: \(forceReload)")
            return
        }
        let pendingTransactionsToRequest = transactionsScheduledForUpdate
        transactionsScheduledForUpdate = []

        ExpressLogger.info("Setup update pending express transactions statuses task. Number of records: \(pendingTransactionsToRequest.count)")
        updateTask = Task { [weak self] in
            do {
                ExpressLogger.info("Start loading pending transactions status. Number of records to request: \(pendingTransactionsToRequest.count)")
                var transactionsToSchedule = [PendingExpressTransaction]()
                var transactionsInProgress = [PendingExpressTransaction]()
                var transactionsToUpdateInRepository = [ExpressPendingTransactionRecord]()
                var polledTransactions = [ExchangeTransaction]()

                for pendingTransaction in pendingTransactionsToRequest {
                    try Task.checkCancellation()

                    let record = pendingTransaction.transactionRecord

                    // We have not any sense to update the terminated status
                    guard !record.transactionStatus.isTerminated(branch: .swap) else {
                        transactionsInProgress.append(pendingTransaction)
                        transactionsToSchedule.append(pendingTransaction)
                        continue
                    }

                    guard let (loadedPendingTransaction, polledTransaction) = try await self?.loadPendingTransactionStatus(for: record) else {
                        // If received error from backend and transaction was already displayed on TokenDetails screen
                        // we need to send previously received transaction, otherwise it will hide on TokenDetails
                        if let previousResult = self?.latestDisplayed.first(where: { $0.transactionRecord.expressTransactionId == record.expressTransactionId }) {
                            transactionsInProgress.append(previousResult)
                        }
                        transactionsToSchedule.append(pendingTransaction)
                        continue
                    }

                    polledTransactions.append(polledTransaction)

                    // We need to send finished transaction one more time to properly update status on bottom sheet
                    transactionsInProgress.append(loadedPendingTransaction)

                    if record.transactionStatus != loadedPendingTransaction.transactionRecord.transactionStatus {
                        transactionsToUpdateInRepository.append(loadedPendingTransaction.transactionRecord)
                    }

                    transactionsToSchedule.append(loadedPendingTransaction)
                }

                try Task.checkCancellation()

                self?.transactionsScheduledForUpdate = transactionsToSchedule
                self?.latestDisplayed = transactionsInProgress
                self?.subscribers.broadcast(
                    ExchangeStatusPollIteration(
                        displayed: transactionsInProgress,
                        changed: transactionsToUpdateInRepository,
                        polled: polledTransactions
                    )
                )

                try await Task.sleep(for: .seconds(Constants.statusUpdateTimeout))

                ExpressLogger.info("Not all pending transactions finished. Requesting after status update after timeout for \(transactionsToSchedule.count) transaction(s)")
                self?.updateTransactionsStatuses(forceReload: true)
            } catch {
                if error is CancellationError || Task.isCancelled {
                    ExpressLogger.info("Pending express txs status check task was cancelled")
                    return
                }

                ExpressLogger.error("Attempting to repeat exchange status updates. Number of requests: \(pendingTransactionsToRequest.count)", error: error)
                self?.transactionsScheduledForUpdate = pendingTransactionsToRequest
                self?.updateTransactionsStatuses(forceReload: false)
            }
        }
    }

    private func filterRelatedTokenTransactions(list: [ExpressPendingTransactionRecord]) -> [ExpressPendingTransactionRecord] {
        list.filter { record in
            guard !record.isHidden else {
                return false
            }

            // We should show only `supportStatusTracking` transaction on UI
            guard record.provider.type.supportStatusTracking else {
                return false
            }

            let isSourceWallet = userWalletId.stringValue == record.sourceTokenTxInfo.userWalletId
            let isDestinationWallet = userWalletId.stringValue == record.destinationTokenTxInfo.userWalletId

            let isSourceToken = tokenItem == record.sourceTokenTxInfo.tokenItem
            let isDestinationToken = tokenItem == record.destinationTokenTxInfo.tokenItem

            let isRelatedWallet = isSourceWallet || isDestinationWallet
            let isRelatedToken = isSourceToken || isDestinationToken

            return isRelatedWallet && isRelatedToken
        }
    }

    private func loadPendingTransactionStatus(
        for transactionRecord: ExpressPendingTransactionRecord
    ) async throws -> (pending: PendingExpressTransaction, raw: ExchangeTransaction)? {
        do {
            ExpressLogger.info("Requesting exchange status for transaction with id: \(transactionRecord.expressTransactionId)")
            let sourceUserWalletId = transactionRecord.expressUserWalletId ?? transactionRecord.sourceTokenTxInfo.userWalletId ?? userWalletId.stringValue
            let refcode = userWalletRepository.models
                .first(where: { $0.userWalletId.stringValue == sourceUserWalletId })?
                .refcodeProvider?.getRefcode()
            let provider = cachingExpressAPIProviderFactory.provider(for: sourceUserWalletId, refcode: refcode)
            let expressTransaction = try await provider.exchangeStatus(transactionId: transactionRecord.expressTransactionId)

            try Task.checkCancellation()

            let refundedTokenItem = await handleRefundedTokenIfNeeded(
                blockchainNetwork: transactionRecord.sourceTokenTxInfo.tokenItem.blockchainNetwork,
                providerType: transactionRecord.provider.type,
                refundedCurrency: expressTransaction.refund?.currency
            )

            try Task.checkCancellation()

            let pendingTransaction = pendingTransactionFactory.buildPendingExpressTransaction(
                expressTransaction: expressTransaction,
                refundedTokenItem: refundedTokenItem,
                for: transactionRecord
            )

            ExpressLogger.info("Transaction status: \(expressTransaction.status.rawValue)")
            ExpressLogger.info("Refunded token: \(String(describing: refundedTokenItem))")

            await pendingExpressTransactionAnalyticsTracker.trackStatusForSwapTransaction(
                transactionId: pendingTransaction.transactionRecord.expressTransactionId,
                tokenSymbol: tokenItem.currencySymbol,
                status: pendingTransaction.transactionRecord.transactionStatus,
                provider: pendingTransaction.transactionRecord.provider
            )

            return (pendingTransaction, expressTransaction)
        } catch {
            // Propagating cancellation
            if error is CancellationError || Task.isCancelled {
                throw error
            }

            ExpressLogger.error("Failed to load status info for transaction with id: \(transactionRecord.expressTransactionId)", error: error)

            return nil
        }
    }

    private func handleRefundedTokenIfNeeded(
        blockchainNetwork: BlockchainNetwork,
        providerType: ExpressPendingTransactionRecord.ProviderType,
        refundedCurrency: ExpressCurrency?,
    ) async -> TokenItem? {
        guard providerType == .dexBridge, let refundedCurrency else {
            return nil
        }

        return try? await expressRefundedTokenHandler.handle(
            blockchainNetwork: blockchainNetwork,
            expressCurrency: refundedCurrency
        )
    }
}

// MARK: - ExpressStatusPolling protocol conformance

extension ExchangeStatusPoller: ExpressStatusPolling {
    @discardableResult
    func subscribe(_ handler: @escaping (ExchangeStatusPollIteration) -> Void) -> Cancellable {
        subscribers.subscribe(handler)
    }
}

// MARK: - CustomStringConvertible protocol conformance

extension ExchangeStatusPoller: CustomStringConvertible {
    var description: String {
        objectDescription(self)
    }
}

// MARK: - Constants

private extension ExchangeStatusPoller {
    enum Constants {
        static let statusUpdateTimeout: TimeInterval = 10
    }
}
