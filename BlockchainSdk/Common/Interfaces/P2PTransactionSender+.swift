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
        executeSend: @escaping ([String]) async throws -> [String]
    ) async throws -> [TransactionSendResult] {
        let rawTransactions = try await buildRawTransactions(
            from: transactions,
            publicKey: wallet.publicKey,
            signer: signer
        )

        let hashes = try await executeSend(rawTransactions)

        return hashes.map { TransactionSendResult(hash: $0, currentProviderHost: .empty) }
    }
}
