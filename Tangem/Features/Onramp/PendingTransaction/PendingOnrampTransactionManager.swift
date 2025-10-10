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
    private let walletModel: any WalletModel
    private let expressAPIProvider: ExpressAPIProvider

    private let pendingOnrampTransactionFactory = PendingOnrampTransactionFactory()

    private lazy var pollingService: PollingService<PendingOnrampTransaction, PendingOnrampTransaction> = PollingService(
        request: { [weak self] pendingTransaction in
            await self?.request(pendingTransaction: pendingTransaction)
        },
        shouldStopPolling: { $0.transactionRecord.transactionStatus.isTerminated(branch: .onramp) },
        hasChanges: { $0.transactionRecord.transactionStatus != $1.transactionRecord.transactionStatus },
        pollingInterval: Constants.statusUpdateTimeout
    )

    private let pendingTransactionsSubject = CurrentValueSubject<[PendingOnrampTransaction], Never>([])

    private var pollingInitiatingTask: Task<Void, Never>?
    private var pollingResultTask: Task<Void, Never>?

    private var tokenItem: TokenItem { walletModel.tokenItem }

    init(
        userWalletId: String,
        walletModel: any WalletModel,
        expressAPIProvider: ExpressAPIProvider
    ) {
        self.userWalletId = userWalletId
        self.walletModel = walletModel
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

        runTask { [weak self] in
            let previousAndCurrentRequestsSequence = await previousAndCurrentRequestsPublisher.values

            for await previousAndCurrentRequests in previousAndCurrentRequestsSequence {
                guard let self else { return }

                let previous = previousAndCurrentRequests.previous
                let current = previousAndCurrentRequests.current

                let shouldForceReload = previous?.count ?? 0 != current.count
                await pollingService.startPolling(requests: current, force: shouldForceReload)

                // If polling requests is empty, it means that
                // `manager.filterRelatedTokenTransactions(list: txRecords)`
                // has filtered out records, so we should send an empty array
                // Otherwise, filtered out transactions will stay on screen
                if current.isEmpty {
                    pendingTransactionsSubject.send([])
                }
            }
        }

        runTask { [weak self] in
            guard let stream = await self?.pollingService.resultStream else { return }
            for await responses in stream {
                guard let self else { return }

                let transactions = responses.map(\.data).sorted(by: \.transactionRecord.date)
                let transactionsToUpdateInRepository = responses.compactMap { response in
                    response.hasChanges ? response.data.transactionRecord : nil
                }

                pendingTransactionsSubject.send(transactions)
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

extension CommonPendingOnrampTransactionsManager {
    enum Constants {
        static let statusUpdateTimeout: Double = 10
    }
}
