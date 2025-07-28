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

protocol PendingExpressTransactionsManager: AnyObject {
    var pendingTransactions: [PendingTransaction] { get }
    var pendingTransactionsPublisher: AnyPublisher<[PendingTransaction], Never> { get }

    func hideTransaction(with id: String)
}

class CommonPendingExpressTransactionsManager {
    @Injected(\.expressPendingTransactionsRepository) private var expressPendingTransactionsRepository: ExpressPendingTransactionRepository
    @Injected(\.pendingExpressTransactionAnalayticsTracker) private var pendingExpressTransactionAnalyticsTracker: PendingExpressTransactionAnalyticsTracker

    private let userWalletId: String
    private let walletModel: any WalletModel
    private let expressAPIProvider: ExpressAPIProvider
    private let expressRefundedTokenHandler: ExpressRefundedTokenHandler

    private let transactionsToUpdateStatusSubject = CurrentValueSubject<[ExpressPendingTransactionRecord], Never>([])
    private let transactionsInProgressSubject = CurrentValueSubject<[PendingExpressTransaction], Never>([])
    private let pendingTransactionFactory = PendingExpressTransactionFactory()

    private var bag = Set<AnyCancellable>()
    private var updateTask: Task<Void, Never>?
    private var transactionsScheduledForUpdate: [PendingExpressTransaction] = []
    private var tokenItem: TokenItem { walletModel.tokenItem }

    init(
        userWalletId: String,
        walletModel: any WalletModel,
        expressAPIProvider: ExpressAPIProvider,
        expressRefundedTokenHandler: ExpressRefundedTokenHandler
    ) {
        self.userWalletId = userWalletId
        self.walletModel = walletModel
        self.expressAPIProvider = expressAPIProvider
        self.expressRefundedTokenHandler = expressRefundedTokenHandler

        bind()
    }

    deinit {
        ExpressLogger.debug(self)
        cancelTask()
    }

    private func bind() {
        expressPendingTransactionsRepository
            .transactionsPublisher
            .withWeakCaptureOf(self)
            .map { manager, txRecords in
                manager.filterRelatedTokenTransactions(list: txRecords)
            }
            .assign(to: \.transactionsToUpdateStatusSubject.value, on: self, ownership: .weak)
            .store(in: &bag)

        transactionsToUpdateStatusSubject
            .removeDuplicates()
            .map { transactions in
                let factory = PendingExpressTransactionFactory()
                let savedPendingTransactions = transactions.map(factory.buildPendingExpressTransaction(for:))
                return savedPendingTransactions
            }
            .withWeakCaptureOf(self)
            .sink { manager, transactions in
                ExpressLogger.info("Receive new transactions to update: \(transactions.count). Number of already scheduled transactions: \(manager.transactionsScheduledForUpdate.count)")
                // If transactions updated their statuses only no need to cancel currently scheduled task and force reload it
                let shouldForceReload = manager.transactionsScheduledForUpdate.count != transactions.count
                manager.transactionsScheduledForUpdate = transactions
                manager.transactionsInProgressSubject.send(transactions)
                manager.updateTransactionsStatuses(forceReload: shouldForceReload)
            }
            .store(in: &bag)
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

                for pendingTransaction in pendingTransactionsToRequest {
                    let record = pendingTransaction.transactionRecord

                    // We have not any sense to update the terminated status
                    guard !record.transactionStatus.isTerminated(branch: .swap) else {
                        transactionsInProgress.append(pendingTransaction)
                        transactionsToSchedule.append(pendingTransaction)
                        continue
                    }

                    guard let loadedPendingTransaction = await self?.loadPendingTransactionStatus(for: record) else {
                        // If received error from backend and transaction was already displayed on TokenDetails screen
                        // we need to send previously received transaction, otherwise it will hide on TokenDetails
                        if let previousResult = self?.transactionsInProgressSubject.value.first(where: { $0.transactionRecord.expressTransactionId == record.expressTransactionId }) {
                            transactionsInProgress.append(previousResult)
                        }
                        transactionsToSchedule.append(pendingTransaction)
                        continue
                    }

                    // We need to send finished transaction one more time to properly update status on bottom sheet
                    transactionsInProgress.append(loadedPendingTransaction)

                    if record.transactionStatus != loadedPendingTransaction.transactionRecord.transactionStatus {
                        transactionsToUpdateInRepository.append(loadedPendingTransaction.transactionRecord)
                    }

                    // If transaction is done we have to update balance
                    if loadedPendingTransaction.transactionRecord.transactionStatus.isDone {
                        self?.walletModel.update(silent: true)
                    }

                    transactionsToSchedule.append(loadedPendingTransaction)
                    try Task.checkCancellation()
                }

                try Task.checkCancellation()

                self?.transactionsScheduledForUpdate = transactionsToSchedule
                self?.transactionsInProgressSubject.send(transactionsInProgress)

                if !transactionsToUpdateInRepository.isEmpty {
                    ExpressLogger.info("Some transactions updated state. Recording changes to repository. Number of updated transactions: \(transactionsToUpdateInRepository.count)")
                    // No need to continue execution, because after update new request will be performed
                    self?.expressPendingTransactionsRepository.updateItems(transactionsToUpdateInRepository)
                }

                try Task.checkCancellation()

                try await Task.sleep(seconds: Constants.statusUpdateTimeout)

                try Task.checkCancellation()

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

            guard record.userWalletId == userWalletId else {
                return false
            }

            let isRelatedToken = walletModel.addresses.contains(where: {
                $0.value == record.sourceTokenTxInfo.address || $0.value == record.destinationTokenTxInfo.address
            })

            return isRelatedToken
        }
    }

    private func loadPendingTransactionStatus(for transactionRecord: ExpressPendingTransactionRecord) async -> PendingExpressTransaction? {
        do {
            ExpressLogger.info("Requesting exchange status for transaction with id: \(transactionRecord.expressTransactionId)")
            let expressTransaction = try await expressAPIProvider.exchangeStatus(transactionId: transactionRecord.expressTransactionId)
            let refundedTokenItem = await handleRefundedTokenIfNeeded(for: expressTransaction, providerType: transactionRecord.provider.type)

            let transactionParams = PendingExpressTransactionParams(
                externalStatus: expressTransaction.externalStatus,
                averageDuration: expressTransaction.averageDuration,
                createdAt: expressTransaction.createdAt
            )

            let pendingTransaction = pendingTransactionFactory.buildPendingExpressTransaction(
                with: transactionParams,
                refundedTokenItem: refundedTokenItem,
                for: transactionRecord
            )

            ExpressLogger.info("Transaction external status: \(expressTransaction.externalStatus.rawValue)")
            ExpressLogger.info("Refunded token: \(String(describing: refundedTokenItem))")

            pendingExpressTransactionAnalyticsTracker.trackStatusForSwapTransaction(
                transactionId: pendingTransaction.transactionRecord.expressTransactionId,
                tokenSymbol: tokenItem.currencySymbol,
                status: pendingTransaction.transactionRecord.transactionStatus,
                provider: pendingTransaction.transactionRecord.provider
            )
            return pendingTransaction
        } catch {
            ExpressLogger.error("Failed to load status info for transaction with id: \(transactionRecord.expressTransactionId)", error: error)
            return nil
        }
    }

    private func handleRefundedTokenIfNeeded(
        for transaction: ExpressTransaction,
        providerType: ExpressPendingTransactionRecord.ProviderType
    ) async -> TokenItem? {
        guard providerType == .dexBridge,
              let refundedCurrency = transaction.refundedCurrency else {
            return nil
        }

        return try? await expressRefundedTokenHandler.handle(expressCurrency: refundedCurrency)
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

extension CommonPendingExpressTransactionsManager {
    enum Constants {
        static let statusUpdateTimeout: Double = 10
    }
}
