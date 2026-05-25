//
//  TangemPayTransactionDispatcher.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct TangemPayTransactionDispatcher {
    let sender: TangemPayWithdrawSender
}

// MARK: - TransactionDispatcher

extension TangemPayTransactionDispatcher: TransactionDispatcher {
    var hasNFCInteraction: Bool { true }

    func send(transaction: TransactionDispatcherTransactionType) async throws -> TransactionDispatcherResult {
        switch transaction {
        case .transfer(let transaction):
            return try await sender.send(
                amount: transaction.amount.value,
                destination: transaction.destinationAddress
            )

        case .cex(let data, _):
            return try await sender.send(
                amount: data.txValue,
                destination: data.destinationAddress
            )

        default:
            throw TransactionDispatcherResult.Error.transactionNotFound
        }
    }
}
