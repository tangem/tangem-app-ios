//
//  CommonExpressPendingTransactionRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

class CommonExpressPendingTransactionRepository {
    @Injected(\.persistentStorage) private var storage: PersistentStorageProtocol

    private let lockQueue = DispatchQueue(label: "com.tangem.CommonExpressPendingTransactionRepository.lockQueue")

    private var pendingTransactionSubject = CurrentValueSubject<[ExpressPendingTransactionRecord], Never>([])

    init() {
        loadPendingTransactions()
    }

    private func loadPendingTransactions() {
        do {
            pendingTransactionSubject.value = try storage.value(for: .pendingExpressTransactions) ?? []
        } catch {
            AppLogger.error("Couldn't get the express transactions list from the storage", error: error)
        }
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
            AppLogger.error("Failed to save changes in storage", error: error)
        }
    }
}

extension CommonExpressPendingTransactionRepository: ExpressPendingTransactionRepository {
    var transactions: [ExpressPendingTransactionRecord] {
        pendingTransactionSubject.value
    }

    var transactionsPublisher: AnyPublisher<[ExpressPendingTransactionRecord], Never> {
        pendingTransactionSubject
            .eraseToAnyPublisher()
    }

    func swapTransactionDidSend(_ txData: SentExpressTransactionData) {
        let expressPendingTransactionRecord = ExpressPendingTransactionRecord(
            expressTransactionId: txData.expressTransactionData.expressTransactionId,
            transactionType: .type(from: txData.expressTransactionData.transactionType),
            transactionHash: txData.result.hash,
            sourceTokenTxInfo: .init(
                userWalletId: txData.source.userWalletId.stringValue,
                tokenItem: txData.source.tokenItem,
                address: txData.source.address ?? .unknown,
                amountString: txData.expressTransactionData.fromAmount.stringValue,
                isCustom: txData.source.isCustom
            ),
            destinationTokenTxInfo: .init(
                userWalletId: txData.destination.userWalletId.stringValue,
                tokenItem: txData.destination.tokenItem,
                address: txData.destination.address ?? .unknown,
                amountString: txData.expressTransactionData.toAmount.stringValue,
                isCustom: txData.destination.isCustom
            ),
            feeString: txData.fee.value.value?.amount.value.stringValue ?? "",
            provider: .init(provider: txData.provider),
            date: txData.date,
            externalTxId: txData.expressTransactionData.externalTxId,
            externalTxURL: txData.expressTransactionData.externalTxUrl,
            averageDuration: nil, // Set nil because we don't have any data yet
            createdAt: nil, // Set nil because we don't have any data yet
            isHidden: false,
            transactionStatus: .awaitingDeposit
        )

        lockQueue.async { [weak self] in
            self?.addRecordIfNeeded(expressPendingTransactionRecord)
        }
    }

    func swapTransactionDidSend(_ transaction: SentSwapTransactionData) {
        let expressPendingTransactionRecord = ExpressPendingTransactionRecord(
            expressTransactionId: transaction.expressTransactionData.expressTransactionId,
            transactionType: .type(from: transaction.expressTransactionData.transactionType),
            transactionHash: transaction.result.hash,
            sourceTokenTxInfo: .init(
                userWalletId: transaction.source.userWalletInfo.id.stringValue,
                tokenItem: transaction.source.tokenItem,
                address: transaction.source.address ?? .unknown,
                amountString: transaction.expressTransactionData.fromAmount.stringValue,
                isCustom: transaction.source.isCustom
            ),
            destinationTokenTxInfo: .init(
                userWalletId: transaction.receive.userWalletInfo.id.stringValue,
                tokenItem: transaction.receive.tokenItem,
                address: transaction.receive.address ?? .unknown,
                amountString: transaction.expressTransactionData.toAmount.stringValue,
                isCustom: transaction.receive.isCustom
            ),
            feeString: transaction.fee.amount.value.stringValue,
            provider: .init(provider: transaction.provider),
            date: transaction.date,
            externalTxId: transaction.expressTransactionData.externalTxId,
            externalTxURL: transaction.expressTransactionData.externalTxUrl,
            averageDuration: nil, // Set nil because we don't have any data yet
            createdAt: nil, // Set nil because we don't have any data yet
            isHidden: false,
            transactionStatus: .awaitingDeposit
        )

        lockQueue.async { [weak self] in
            self?.addRecordIfNeeded(expressPendingTransactionRecord)
        }
    }

    func hideSwapTransaction(with id: String) {
        lockQueue.async { [weak self] in
            guard let self else { return }

            guard let index = pendingTransactionSubject.value.firstIndex(where: { $0.expressTransactionId == id }) else {
                return
            }

            pendingTransactionSubject.value[index].isHidden = true
            saveChanges()
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
