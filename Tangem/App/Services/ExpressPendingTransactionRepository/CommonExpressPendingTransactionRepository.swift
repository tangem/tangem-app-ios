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

    private var userWalletId: UserWalletId?
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

    private func logNotInitializedRepository(with message: String) {
        assertionFailure("Repository not initialized")
        log("\(message) Reason: Failed to find UserWalletId")
    }

    private func log<T>(_ message: @autoclosure () -> T) {
        AppLog.shared.debug("[Express Tx Repository] \(message())")
    }
}

extension CommonExpressPendingTransactionRepository: ExpressPendingTransactionRepository {
    var pendingTransactionsPublisher: AnyPublisher<[ExpressPendingTransactionRecord], Never> {
        pendingTransactionSubject.eraseToAnyPublisher()
    }

    func initializeForUserWallet(with userWalletId: UserWalletId) {
        self.userWalletId = userWalletId
    }

    func lastCurrencyTransaction() -> ExpressCurrency? {
        lockQueue.sync {
            return pendingTransactionSubject.value.last?.destinationTokenTxInfo.tokenItem.expressCurrency
        }
    }

    func hasPendingTransaction(in networkid: String) -> Bool {
        guard let userWalletId else {
            return false
        }

        return lockQueue.sync {
            pendingTransactionSubject.value.contains { record in
                guard record.userWalletId == userWalletId.stringValue else {
                    return false
                }

                return record.destinationTokenTxInfo.tokenItem.networkId == networkid ||
                    record.sourceTokenTxInfo.tokenItem.networkId == networkid
            }
        }
    }

    func didSendSwapTransaction(_ txData: SentExpressTransactionData) {
        guard case .send = txData.expressTransactionData.transactionType else {
            log("No need to store DEX transactions. Skipping")
            return
        }

        guard let userWalletId else {
            logNotInitializedRepository(with: "Failed to save pending Swap transaction.")
            return
        }

        let expressPendingTransactionRecord = ExpressPendingTransactionRecord(
            userWalletId: userWalletId.stringValue,
            expressTransactionId: txData.expressTransactionData.expressTransactionId,
            transactionType: .type(from: txData.expressTransactionData.transactionType),
            transactionHash: txData.hash,
            sourceTokenTxInfo: .init(
                tokenItem: txData.source.tokenItem,
                blockchainNetwork: txData.source.blockchainNetwork,
                amount: txData.expressTransactionData.fromAmount,
                isCustom: txData.source.isCustom
            ),
            destinationTokenTxInfo: .init(
                tokenItem: txData.destination.tokenItem,
                blockchainNetwork: txData.destination.blockchainNetwork,
                amount: txData.expressTransactionData.toAmount,
                isCustom: txData.destination.isCustom
            ),
            fee: txData.fee,
            provider: .init(provider: txData.provider),
            date: txData.date,
            externalTxId: txData.expressTransactionData.externalTxId,
            externalTxURL: txData.expressTransactionData.externalTxUrl
        )

        lockQueue.sync {
            addRecordIfNeeded(expressPendingTransactionRecord)
        }
    }

    func didSendApproveTransaction() {}

    func removeSwapTransaction(with expressTxId: String) {
        lockQueue.sync {
            guard let index = pendingTransactionSubject.value.firstIndex(where: { $0.expressTransactionId == expressTxId }) else {
                log("Trying to remove transaction that not in repository.")
                return
            }

            pendingTransactionSubject.value.remove(at: index)
            saveChanges()
        }
    }
}
