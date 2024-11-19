//
//  StakeKitTransactionSender.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation
import TangemSdk

public protocol StakeKitTransactionSender {
    /// Return stream with tx which was sent one by one
    /// If catch error stream will be stopped
    /// In case when manager already implemented the `StakeKitTransactionSenderProvider` method will be not required
    func sendStakeKit(transactions: [StakeKitTransaction], signer: TransactionSigner, delay second: UInt64?) -> AsyncThrowingStream<StakeKitTransactionSendResult, Error>
}

protocol StakeKitTransactionSenderProvider {
    associatedtype RawTransaction

    func prepareDataForSign(transaction: StakeKitTransaction) throws -> Data
    func prepareDataForSend(transaction: StakeKitTransaction, signature: SignatureInfo) throws -> RawTransaction
    func broadcast(transaction: StakeKitTransaction, rawTransaction: RawTransaction) async throws -> String
}

// MARK: - Common implementation for StakeKitTransactionSenderProvider

extension StakeKitTransactionSender where Self: StakeKitTransactionSenderProvider, Self: WalletProvider, RawTransaction: CustomStringConvertible {
    func sendStakeKit(transactions: [StakeKitTransaction], signer: TransactionSigner, delay second: UInt64?) -> AsyncThrowingStream<StakeKitTransactionSendResult, Error> {
        .init { [weak self] continuation in
            let task = Task { [weak self] in
                guard let self else {
                    continuation.finish()
                    return
                }

                do {
                    let preparedHashes = try transactions.map { try self.prepareDataForSign(transaction: $0) }
                    let signatures: [SignatureInfo] = try await signer.sign(hashes: preparedHashes, walletPublicKey: wallet.publicKey).async()

                    for (transaction, signature) in zip(transactions, signatures) {
                        try Task.checkCancellation()
                        let rawTransaction = try prepareDataForSend(transaction: transaction, signature: signature)

                        do {
                            let result: TransactionSendResult = try await broadcast(transaction: transaction, rawTransaction: rawTransaction)
                            try Task.checkCancellation()
                            continuation.yield(.init(transaction: transaction, result: result))
                        } catch {
                            throw StakeKitTransactionSendError(transaction: transaction, error: error)
                        }

                        if transactions.count > 1, let second {
                            Log.log("\(self) start \(second) second delay between the transactions sending")
                            try await Task.sleep(nanoseconds: second * NSEC_PER_SEC)
                        }
                    }

                    continuation.finish()

                } catch {
                    Log.log("\(self) catch \(error) when sent staking transaction")
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { termination in
                task.cancel()
            }
        }
    }

    /// Convenience method with adding the `PendingTransaction` to the wallet  and `SendTxError` mapping
    private func broadcast(transaction: StakeKitTransaction, rawTransaction: RawTransaction) async throws -> TransactionSendResult {
        do {
            let hash: String = try await broadcast(transaction: transaction, rawTransaction: rawTransaction)
            let mapper = PendingTransactionRecordMapper()
            let record = mapper.mapToPendingTransactionRecord(
                stakeKitTransaction: transaction,
                source: wallet.defaultAddress.value,
                hash: hash
            )

            await addPendingTransaction(record)

            return TransactionSendResult(hash: hash)
        } catch {
            throw SendTxErrorFactory().make(error: error, with: rawTransaction.description)
        }
    }

    @MainActor
    private func addPendingTransaction(_ record: PendingTransactionRecord) {
        wallet.addPendingTransaction(record)
    }
}
