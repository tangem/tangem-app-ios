//
//  StakeKitTransactionSender+.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension StakeKitTransactionSender where
    Self: StakingTransactionsBuilder,
    Self: WalletProvider, RawTransaction: CustomStringConvertible,
    Self: StakeKitTransactionDataBroadcaster,
    Self: BlockchainDataProvider {
    func sendStakeKit(
        transactions: [StakeKitTransaction],
        signer: TransactionSigner,
        transactionStatusProvider: some StakeKitTransactionStatusProvider,
        delay: UInt64?
    ) async throws -> AsyncThrowingStream<StakeKitTransactionSendResult, Error> {
        let rawTransactions = try await buildRawTransactions(
            from: transactions,
            publicKey: wallet.publicKey,
            signer: signer
        )

        return AsyncThrowingStream { continuation in
            let task = Task {
                try await executeTransactionBatch(
                    transactions: transactions,
                    rawTransactions: rawTransactions,
                    delay: delay,
                    transactionStatusProvider: transactionStatusProvider
                ) { result in
                    continuation.yield(result)
                }
                continuation.finish()
            }
            continuation.onTermination = { termination in
                task.cancel()
            }
        }
    }

    private func executeTransactionBatch(
        transactions: [StakeKitTransaction],
        rawTransactions: [RawTransaction],
        delay: UInt64?,
        transactionStatusProvider: StakeKitTransactionStatusProvider,
        onResult: @escaping (StakeKitTransactionSendResult) -> Void
    ) async throws {
        try await withThrowingTaskGroup(of: (TransactionSendResult, StakeKitTransaction).self) { group in
            var results = [TransactionSendResult]()

            for (index, (transaction, rawTransaction)) in zip(transactions, rawTransactions).enumerated() {
                group.addTask {
                    let result: TransactionSendResult = try await self.broadcast(
                        transaction: transaction,
                        rawTransaction: rawTransaction,
                        at: UInt64(index),
                        delay: delay,
                        currentProviderHost: self.currentHost
                    )
                    return (result, transaction)
                }

                if transaction.requiresWaitingToComplete {
                    guard let result = try await group.next() else { continue }
                    results.append(result.0)

                    onResult(StakeKitTransactionSendResult(transaction: result.1, result: result.0))

                    try await self.waitForTransactionToComplete(
                        transaction,
                        transactionStatusProvider: transactionStatusProvider
                    )
                }
            }

            for try await result in group where !results.contains(result.0) {
                onResult(StakeKitTransactionSendResult(transaction: result.1, result: result.0))
            }
        }
    }

    /// Convenience method with adding the `PendingTransaction` to the wallet  and `SendTxError` mapping
    private func broadcast(
        transaction: StakeKitTransaction,
        rawTransaction: RawTransaction,
        at index: UInt64,
        delay: UInt64? = nil,
        currentProviderHost: String
    ) async throws -> TransactionSendResult {
        try Task.checkCancellation()
        if index > 0, let delay {
            BSDKLogger.info("Start \(delay) second delay between the transactions sending")
            try await Task.sleep(nanoseconds: index * delay * NSEC_PER_SEC)
            try Task.checkCancellation()
        }

        do {
            let hash: String = try await broadcast(rawTransaction: rawTransaction)
            try Task.checkCancellation()
            let mapper = PendingTransactionRecordMapper()
            let record = mapper.mapToPendingTransactionRecord(
                stakingTransaction: transaction,
                source: wallet.defaultAddress.value,
                hash: hash
            )

            await addPendingTransaction(record)

            return TransactionSendResult(hash: hash, currentProviderHost: currentProviderHost)
        } catch let sendTxError as SendTxError {
            throw sendTxError
        } catch {
            throw SendTxError(error: error.toUniversalError(), tx: rawTransaction.description)
        }
    }

    private func waitForTransactionToComplete(
        _ transaction: StakeKitTransaction,
        transactionStatusProvider: StakeKitTransactionStatusProvider
    ) async throws {
        var status: StakeKitTransaction.Status?
        let startPollingDate = Date()
        while status != .confirmed,
              Date().timeIntervalSince(startPollingDate) < StakingTransactionSenderConstants.pollingTimeout {
            try await Task.sleep(nanoseconds: StakingTransactionSenderConstants.pollingDelayInSeconds * NSEC_PER_SEC)
            status = try await transactionStatusProvider.transactionStatus(transaction)
        }
    }

    @MainActor
    private func addPendingTransaction(_ record: PendingTransactionRecord) {
        wallet.addPendingTransaction(record)
    }
}

extension StakeKitTransaction {
    var requiresWaitingToComplete: Bool {
        type == .split
    }
}

private enum StakingTransactionSenderConstants {
    static let pollingDelayInSeconds: UInt64 = 3
    static let pollingTimeout: TimeInterval = 30
}
