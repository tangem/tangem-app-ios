//
//  PendingExpressTransactionsManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSwapping

protocol PendingExpressTransactionsManager: AnyObject {
    var pendingTransactions: [PendingExpressTransaction] { get }
    var pendingTransactionsPublisher: AnyPublisher<[PendingExpressTransaction], Never> { get }
}

class CommonPendingExpressTransactionsManager {
    @Injected(\.expressPendingTransactionsRepository) private var expressPendingTransactionsRepository: ExpressPendingTransactionRepository
    @Injected(\.pendingExpressTransactionAnalayticsTracker) private var pendingExpressTransactionAnalyticsTracker: PendingExpressTransactionAnalyticsTracker

    private let userWalletId: String
    private let blockchainNetwork: BlockchainNetwork
    private let tokenItem: TokenItem
    private let expressAPIProvider: ExpressAPIProvider

    private let transactionsToUpdateStatusSubject = CurrentValueSubject<[ExpressPendingTransactionRecord], Never>([])
    private let transactionsInProgressSubject = CurrentValueSubject<[PendingExpressTransaction], Never>([])
    private let pendingTransactionFactory = PendingExpressTransactionFactory()

    private var bag = Set<AnyCancellable>()
    private var updateTask: Task<Void, Never>?

    init(
        userWalletId: String,
        blockchainNetwork: BlockchainNetwork,
        tokenItem: TokenItem
    ) {
        self.userWalletId = userWalletId
        self.blockchainNetwork = blockchainNetwork
        self.tokenItem = tokenItem
        expressAPIProvider = ExpressAPIProviderFactory().makeExpressAPIProvider(userId: userWalletId, logger: AppLog.shared)

        bind()
    }

    deinit {
        print("CommonPendingExpressTransactionsManager deinit")
        cancelTask()
    }

    private func bind() {
        expressPendingTransactionsRepository.pendingTransactionsPublisher
            .withWeakCaptureOf(self)
            .map { manager, txRecords in
                manager.filterRelatedTokenTransactions(list: txRecords)
            }
            .assign(to: \.transactionsToUpdateStatusSubject.value, on: self, ownership: .weak)
            .store(in: &bag)

        transactionsToUpdateStatusSubject
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { tracker, transactions in
                tracker.updateTransactionsStatuses(transactions)
            }
            .store(in: &bag)
    }

    private func cancelTask() {
        if updateTask != nil {
            updateTask?.cancel()
            updateTask = nil
        }
    }

    private func updateTransactionsStatuses(_ records: [ExpressPendingTransactionRecord]) {
        cancelTask()

        if records.isEmpty {
            return
        }

        log("Setup update pending express transactions statuses task. Number of records: \(records.count)")
        updateTask = Task { [weak self] in
            do {
                self?.log("Start loading pending transactions status. Number of records to request: \(records.count)")
                var recordsToRequest = [ExpressPendingTransactionRecord]()
                var transactionsInProgress = [PendingExpressTransaction]()
                for record in records {
                    guard let pendingTransaction = await self?.loadPendingTransactionStatus(for: record) else {
                        // If received error from backend and transaction was already displayed on TokenDetails screen
                        // we need to send previously received transaction, otherwise it will hide on TokenDetails
                        if let previousResult = self?.transactionsInProgressSubject.value.first(where: { $0.transactionRecord.expressTransactionId == record.expressTransactionId }) {
                            transactionsInProgress.append(previousResult)
                        }
                        recordsToRequest.append(record)
                        continue
                    }

                    // We need to send finished transaction one more time to properly update status on bottom sheet
                    transactionsInProgress.append(pendingTransaction)
                    guard pendingTransaction.currentStatus.isTransactionInProgress else {
                        self?.removeTransactionFromRepository(record)
                        continue
                    }

                    recordsToRequest.append(record)
                    try Task.checkCancellation()
                }

                self?.transactionsInProgressSubject.send(transactionsInProgress)

                try Task.checkCancellation()

                try await Task.sleep(seconds: Constants.statusUpdateTimeout)

                try Task.checkCancellation()

                self?.log("Not all pending transactions finished. Requesting after status update after timeout for \(recordsToRequest.count) transaction(s)")
                self?.updateTransactionsStatuses(recordsToRequest)
            } catch {
                if error is CancellationError || Task.isCancelled {
                    self?.log("Pending express txs status check task was cancelled")
                    return
                }

                self?.log("Catch error: \(error.localizedDescription). Attempting to repeat exchange status updates. Number of requests: \(records.count)")
                self?.updateTransactionsStatuses(records)
            }
        }
    }

    private func filterRelatedTokenTransactions(list: [ExpressPendingTransactionRecord]) -> [ExpressPendingTransactionRecord] {
        return list.filter { record in
            guard record.userWalletId == userWalletId else {
                return false
            }

            let isSameBlockchain = record.sourceTokenTxInfo.blockchainNetwork == blockchainNetwork
                || record.destinationTokenTxInfo.blockchainNetwork == blockchainNetwork
            let isSameTokenItem = record.sourceTokenTxInfo.tokenItem == tokenItem
                || record.destinationTokenTxInfo.tokenItem == tokenItem

            return isSameBlockchain && isSameTokenItem
        }
    }

    private func loadPendingTransactionStatus(for transactionRecord: ExpressPendingTransactionRecord) async -> PendingExpressTransaction? {
        do {
            log("Requesting exchange status for transaction with id: \(transactionRecord.expressTransactionId)")
            let expressTransaction = try await expressAPIProvider.exchangeStatus(transactionId: transactionRecord.expressTransactionId)
            let pendingTransaction = pendingTransactionFactory.buildPendingExpressTransaction(currentExpressStatus: expressTransaction.externalStatus, for: transactionRecord)
            log("Transaction external status: \(expressTransaction.externalStatus.rawValue)")
            pendingExpressTransactionAnalyticsTracker.trackStatusForTransaction(
                with: transactionRecord.expressTransactionId,
                tokenSymbol: tokenItem.currencySymbol,
                status: pendingTransaction.currentStatus
            )
            return pendingTransaction
        } catch {
            log("Failed to load status info for transaction with id: \(transactionRecord.expressTransactionId). Error: \(error)")
            return nil
        }
    }

    private func removeTransactionFromRepository(_ record: ExpressPendingTransactionRecord) {
        expressPendingTransactionsRepository.removeSwapTransaction(with: record.expressTransactionId)
    }

    private func log<T>(_ message: @autoclosure () -> T) {
        AppLog.shared.debug("[CommonPendingExpressTransactionsManager] \(message())")
    }
}

extension CommonPendingExpressTransactionsManager: PendingExpressTransactionsManager {
    var pendingTransactions: [PendingExpressTransaction] {
        transactionsInProgressSubject.value
    }

    var pendingTransactionsPublisher: AnyPublisher<[PendingExpressTransaction], Never> {
        transactionsInProgressSubject.eraseToAnyPublisher()
    }
}

extension CommonPendingExpressTransactionsManager {
    enum Constants {
        static let statusUpdateTimeout: Double = 10
    }
}
