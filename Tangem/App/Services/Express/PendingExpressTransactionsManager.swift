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

protocol PendingExpressTransactionsManager {
    var pendingTransactions: [PendingExpressTransaction] { get }
    var pendingTransactionsPublisher: AnyPublisher<[PendingExpressTransaction], Never> { get }
}

class CommonPendingExpressTransactionsManager {
    @Injected(\.expressPendingTransactionsRepository) private var expressPendingTransactionsRepository: ExpressPendingTransactionRepository

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
        expressAPIProvider = CommonExpressAPIFactory().makeExpressAPIProvider(userId: userWalletId)

        bind()
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

        updateTask = runTask(in: self) { manager in
            do {
                var recordsToRequest = [ExpressPendingTransactionRecord]()
                var transactionsInProgress = [PendingExpressTransaction]()
                for record in records {
                    guard let pendingTransaction = await manager.loadPendingTransactionStatus(for: record) else {
                        recordsToRequest.append(record)
                        continue
                    }

                    guard pendingTransaction.currentStatus.isTransactionInProgress else {
                        manager.removeTransactionFromRepository(record)
                        continue
                    }

                    recordsToRequest.append(record)
                    transactionsInProgress.append(pendingTransaction)
                    try Task.checkCancellation()
                }

                manager.transactionsInProgressSubject.send(transactionsInProgress)

                try Task.checkCancellation()

                try await Task.sleep(seconds: Constants.statusUpdateTimeout)

                try Task.checkCancellation()

                manager.updateTransactionsStatuses(recordsToRequest)
            } catch {
                if error is CancellationError {
                    manager.log("Pending express txs status check task was cancelled")
                    return
                }

                manager.updateTransactionsStatuses(records)
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
            let expressTransaction = try await expressAPIProvider.exchangeStatus(transactionId: transactionRecord.expressTransactionId)
            let pendingTransaction = pendingTransactionFactory.buildPendingExpressTransaction(currentExpressStatus: expressTransaction.externalStatus, for: transactionRecord)
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
        AppLog.shared.debug("[CommonExpressPendingTxTracker] \(message())")
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
