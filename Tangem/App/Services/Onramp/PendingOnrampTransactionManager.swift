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

class CommonPendingOnrampTransactionsManager {
    @Injected(\.onrampPendingTransactionsRepository) private var onrampPendingTransactionsRepository: OnrampPendingTransactionRepository

    private let userWalletId: String
    private let walletModel: WalletModel
    private let expressAPIProvider: ExpressAPIProvider

    private let pendingTransactionFactory = PendingExpressTransactionFactory()
    private let pollingService: PollingService<PendingOnrampTransaction, PendingOnrampTransaction>

    private let pendingTransactionsSubject = CurrentValueSubject<[PendingOnrampTransaction], Never>([])
    private var bag = Set<AnyCancellable>()
    private var tokenItem: TokenItem { walletModel.tokenItem }

    init(
        userWalletId: String,
        walletModel: WalletModel
    ) {
        self.userWalletId = userWalletId
        self.walletModel = walletModel
        expressAPIProvider = ExpressAPIProviderFactory().makeExpressAPIProvider(userId: userWalletId, logger: AppLog.shared)

        pollingService = PollingService(
            request: { [expressAPIProvider, pendingTransactionFactory] prendinTransaction in
                do {
                    let record = prendinTransaction.transactionRecord
                    let onrampTransaction = try await expressAPIProvider.onrampStatus(transactionId: record.expressTransactionId)
                    let pendingTransaction = pendingTransactionFactory.buildPendingOnrampTransaction(
                        currentOnrampTransaction: onrampTransaction,
                        for: record
                    )
                    return pendingTransaction
                } catch {
                    return nil
                }
            },
            shouldStopPolling: { $0.transactionRecord.transactionStatus.isTerminated },
            hasChanges: { $0.transactionRecord.transactionStatus != $1.transactionRecord.transactionStatus },
            pollingInterval: Constants.statusUpdateTimeout
        )

        bind()
    }

    deinit {
        pollingService.cancelTask()
    }

    private func bind() {
        onrampPendingTransactionsRepository.transactionsPublisher
            .withWeakCaptureOf(self)
            .map { manager, txRecords in
                manager.filterRelatedTokenTransactions(list: txRecords)
            }
            .removeDuplicates()
            .map { transactions in
                let factory = PendingExpressTransactionFactory()
                let savedPendingTransactions = transactions.map(factory.buildPendingOnrampTransaction(for:))
                return savedPendingTransactions
            }
            .withPrevious()
            .sink { [pollingService] previous, current in
                let shouldForceReload = previous?.count ?? 0 != current.count
                pollingService.startPolling(requests: current, force: shouldForceReload)
            }
            .store(in: &bag)

        pollingService
            .resultPublisher
            .map { pendingTransactions in
                pendingTransactions
                    .map(\.data)
                    .sorted(by: \.id)
            }
            .assign(to: \.pendingTransactionsSubject.value, on: self, ownership: .weak)
            .store(in: &bag)

        pollingService.resultPublisher
            .map { responses in
                responses.compactMap { result in
                    result.hasChanges
                        ? result.data.transactionRecord
                        : nil
                }
            }
            .sink { [onrampPendingTransactionsRepository] transactionsToUpdateInRepository in
                onrampPendingTransactionsRepository.updateItems(transactionsToUpdateInRepository)
            }
            .store(in: &bag)
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
