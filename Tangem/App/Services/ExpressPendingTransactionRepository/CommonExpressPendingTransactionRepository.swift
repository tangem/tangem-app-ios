//
//  CommonExpressPendingTransactionRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSwapping

class CommonExpressPendingTransactionRepository {
    @Injected(\.persistentStorage) private var storage: PersistentStorageProtocol

    private let lockQueue = DispatchQueue(label: "com.tangem.CommonExpressPendingTransactionRepository.lockQueue")

    private var pendingTransactionSubject = CurrentValueSubject<[ExpressPendingTransactionRecord], Never>([])

    init() {
        loadPendingTransactions()
    }

    private func loadPendingTransactions() {
        let savedTransactions: [ExpressPendingTransactionRecord] = (try? storage.value(for: .pendingExpressTransactions)) ?? []
        pendingTransactionSubject.value = savedTransactions
    }

    private func addRecordIfNeeded(_ record: ExpressPendingTransactionRecord) {
        if pendingTransactionSubject.value.contains(where: { $0.expressTransactionId == record.expressTransactionId }) {
            return
        }

        pendingTransactionSubject.value.append(record)
        saveChanges()
    }

    private func saveChanges() {
        do {
            try storage.store(value: pendingTransactionSubject.value, for: .pendingExpressTransactions)
        } catch {
            log("Failed to save changes in storage. Reason: \(error)")
        }
    }

    private func log<T>(_ message: @autoclosure () -> T) {
        AppLog.shared.debug("[Express Tx Repository] \(message())")
    }
}

extension CommonExpressPendingTransactionRepository: ExpressPendingTransactionRepository {
    var allExpressTransactions: [ExpressPendingTransactionRecord] {
        pendingTransactionSubject.value
    }

    var pendingCEXTransactionsPublisher: AnyPublisher<[ExpressPendingTransactionRecord], Never> {
        pendingTransactionSubject
            .map { transactions in
                transactions.filter { $0.transactionStatus.isTransactionInProgress && $0.provider.type == .cex }
            }
            .eraseToAnyPublisher()
    }

    func swapTransactionDidSend(_ txData: SentExpressTransactionData, userWalletId: String) {
        let expressPendingTransactionRecord = ExpressPendingTransactionRecord(
            userWalletId: userWalletId,
            expressTransactionId: txData.expressTransactionData.expressTransactionId,
            transactionType: .type(from: txData.expressTransactionData.transactionType),
            transactionHash: txData.hash,
            sourceTokenTxInfo: .init(
                tokenItem: txData.source.tokenItem,
                blockchainNetwork: txData.source.blockchainNetwork,
                amountString: txData.expressTransactionData.fromAmount.stringValue,
                isCustom: txData.source.isCustom
            ),
            destinationTokenTxInfo: .init(
                tokenItem: txData.destination.tokenItem,
                blockchainNetwork: txData.destination.blockchainNetwork,
                amountString: txData.expressTransactionData.toAmount.stringValue,
                isCustom: txData.destination.isCustom
            ),
            feeString: txData.fee.stringValue,
            provider: .init(provider: txData.provider),
            date: txData.date,
            externalTxId: txData.expressTransactionData.externalTxId,
            externalTxURL: txData.expressTransactionData.externalTxUrl,
            transactionStatus: .awaitingDeposit
        )

        lockQueue.async { [weak self] in
            self?.addRecordIfNeeded(expressPendingTransactionRecord)
        }
    }

    func updateItems(_ items: [ExpressPendingTransactionRecord]) {
        if items.isEmpty {
            return
        }

        lockQueue.async { [weak self] in
            guard let self else { return }

            let transactionsToUpdate = items.toDictionary(keyedBy: \.expressTransactionId)
            var hasChanges = false
            var pendingTransactions = pendingTransactionSubject.value
            for (index, item) in pendingTransactions.indexed() {
                guard let updatedTransaction = transactionsToUpdate[item.expressTransactionId] else {
                    continue
                }

                pendingTransactions[index] = updatedTransaction
                hasChanges = true
            }

            guard hasChanges else {
                return
            }

            pendingTransactionSubject.value = pendingTransactions
            saveChanges()
        }
    }
}

extension CommonExpressPendingTransactionRepository: CustomStringConvertible {
    var description: String {
        objectDescription(self)
    }
}
