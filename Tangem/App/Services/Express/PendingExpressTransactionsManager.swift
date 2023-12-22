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
    private var transactionsScheduledForUpdate: [PendingExpressTransaction] = []

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
            .map { transactions in
                let factory = PendingExpressTransactionFactory()
                let savedPendingTransactions = transactions.map(factory.buildPendingExpressTransaction(for:))
                return savedPendingTransactions
            }
            .withWeakCaptureOf(self)
            .handleEvents(receiveOutput: { manager, transactions in
                manager.transactionsScheduledForUpdate = transactions
                manager.transactionsInProgressSubject.send(transactions)
            })
            .sink { manager, transactions in
                manager.updateTransactionsStatuses()
            }
            .store(in: &bag)
    }

    private func cancelTask() {
        if updateTask != nil {
            updateTask?.cancel()
            updateTask = nil
        }
    }

    private func updateTransactionsStatuses() {
        cancelTask()

        if transactionsScheduledForUpdate.isEmpty {
            return
        }
        let pendingTransactionsToRequest = transactionsScheduledForUpdate
        transactionsScheduledForUpdate = []

        log("Setup update pending express transactions statuses task. Number of records: \(pendingTransactionsToRequest.count)")
        updateTask = Task { [weak self] in
            do {
                self?.log("Start loading pending transactions status. Number of records to request: \(pendingTransactionsToRequest.count)")
                var transactionsToSchedule = [PendingExpressTransaction]()
                var transactionsInProgress = [PendingExpressTransaction]()
                var transactionsToUpdateInRepository = [ExpressPendingTransactionRecord]()
                for pendingTransaction in pendingTransactionsToRequest {
                    let record = pendingTransaction.transactionRecord
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
                    guard loadedPendingTransaction.transactionRecord.transactionStatus.isTransactionInProgress else {
                        self?.removeTransactionFromRepository(record)
                        continue
                    }

                    if record.transactionStatus != loadedPendingTransaction.transactionRecord.transactionStatus {
                        transactionsToUpdateInRepository.append(loadedPendingTransaction.transactionRecord)
                    }

                    transactionsToSchedule.append(loadedPendingTransaction)
                    try Task.checkCancellation()
                }

                try Task.checkCancellation()

                self?.transactionsScheduledForUpdate = transactionsToSchedule
                self?.transactionsInProgressSubject.send(transactionsInProgress)

                guard transactionsToUpdateInRepository.isEmpty else {
                    // No need to continue execution, because after update new request will be performed
                    self?.expressPendingTransactionsRepository.updateItems(transactionsToUpdateInRepository)
                    return
                }

                try Task.checkCancellation()

                try await Task.sleep(seconds: Constants.statusUpdateTimeout)

                try Task.checkCancellation()

                self?.log("Not all pending transactions finished. Requesting after status update after timeout for \(transactionsToSchedule.count) transaction(s)")
                self?.updateTransactionsStatuses()
            } catch {
                if error is CancellationError || Task.isCancelled {
                    self?.log("Pending express txs status check task was cancelled")
                    return
                }

                self?.log("Catch error: \(error.localizedDescription). Attempting to repeat exchange status updates. Number of requests: \(pendingTransactionsToRequest.count)")
                self?.transactionsScheduledForUpdate = pendingTransactionsToRequest
                self?.updateTransactionsStatuses()
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
                with: pendingTransaction.transactionRecord.expressTransactionId,
                tokenSymbol: tokenItem.currencySymbol,
                status: pendingTransaction.transactionRecord.transactionStatus
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

extension CommonPendingExpressTransactionsManager {
    enum StatusUpdateResult {
        case repeatRequest(PendingExpressTransaction)
        case requestFailed(ExpressPendingTransactionRecord)
        case txsFinished(PendingExpressTransaction)
        case statusUpdated(PendingExpressTransaction)

        var pendingTransaction: PendingExpressTransaction? {
            switch self {
            case .repeatRequest(let pendingExpressTransaction), .txsFinished(let pendingExpressTransaction), .statusUpdated(let pendingExpressTransaction):
                return pendingExpressTransaction
            case .requestFailed:
                return nil
            }
        }

        var requestTransactionRecord: ExpressPendingTransactionRecord {
            switch self {
            case .repeatRequest(let pendingExpressTransaction), .txsFinished(let pendingExpressTransaction), .statusUpdated(let pendingExpressTransaction):
                return pendingExpressTransaction.transactionRecord
            case .requestFailed(let record):
                return record
            }
        }
    }
}
