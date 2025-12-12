//
//  P2PTransactionSender+.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension P2PTransactionSender where
    Self: StakingTransactionsBuilder,
    Self: WalletManager,
    RawTransaction == String {
    func sendP2P(
        transactions: [P2PTransaction],
        signer: TransactionSigner,
        executeSend: @escaping ([String]) async throws -> [(Int, String)]
    ) async throws -> [TransactionSendResult] {
        let rawTransactions = try await buildRawTransactions(
            from: transactions,
            publicKey: wallet.publicKey,
            signer: signer
        )

        let results = try await executeSend(rawTransactions)

        let mapper = PendingTransactionRecordMapper()
        for (index, hash) in results {
            guard let transaction = transactions[safe: index] else { continue }
            let record = mapper.mapToPendingTransactionRecord(
                stakingTransaction: transaction,
                source: wallet.defaultAddress.value,
                hash: hash
            )

            await addPendingTransaction(record)
        }

        return results.map { TransactionSendResult(hash: $0.1, currentProviderHost: .empty) }
    }

    @MainActor
    private func addPendingTransaction(_ record: PendingTransactionRecord) {
        wallet.addPendingTransaction(record)
    }
}
