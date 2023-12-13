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
    var pendingTransactions: [ExpressPendingTransactionRecord] {
        pendingTransactionSubject.value
    }

    var pendingTransactionsPublisher: AnyPublisher<[ExpressPendingTransactionRecord], Never> {
        pendingTransactionSubject.eraseToAnyPublisher()
    }

    func didSendSwapTransaction(_ txData: SentExpressTransactionData, userWalletId: String) {
        guard case .send = txData.expressTransactionData.transactionType else {
            log("No need to store DEX transactions. Skipping")
            return
        }

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
            externalTxURL: txData.expressTransactionData.externalTxUrl
        )

        lockQueue.async { [weak self] in
            self?.addRecordIfNeeded(expressPendingTransactionRecord)
        }
    }

    func didSendApproveTransaction() {}

    func removeSwapTransaction(with expressTxId: String) {
        lockQueue.async { [weak self] in
            guard let self else { return }

            guard let index = pendingTransactionSubject.value.firstIndex(where: { $0.expressTransactionId == expressTxId }) else {
                log("Trying to remove transaction that not in repository.")
                return
            }

            pendingTransactionSubject.value.remove(at: index)
            saveChanges()
        }
    }
}
