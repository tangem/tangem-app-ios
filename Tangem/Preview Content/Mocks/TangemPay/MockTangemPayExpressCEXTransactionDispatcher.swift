//
//  MockTangemPayExpressCEXTransactionDispatcher.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// Hot wallets in UI tests lack the VISA derivation, so the real dispatcher cannot sign.
struct MockTangemPayExpressCEXTransactionDispatcher: TransactionDispatcher {
    var hasNFCInteraction: Bool { false }

    func send(transaction: TransactionDispatcherTransactionType) async throws -> TransactionDispatcherResult {
        guard case .cex = transaction else {
            throw TransactionDispatcherResult.Error.transactionNotFound
        }

        return TransactionDispatcherResult(
            hash: "0xmocktangempaywithdrawtxhash",
            url: nil,
            signerType: "mock",
            currentHost: "mock"
        )
    }
}
