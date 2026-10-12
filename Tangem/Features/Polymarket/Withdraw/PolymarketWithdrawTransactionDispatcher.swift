//
//  PolymarketWithdrawTransactionDispatcher.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemPolymarket

struct PolymarketWithdrawTransactionDispatcher {
    let withdrawTransactionService: any PolymarketWithdrawing
    let signer: TangemSigner
}

// MARK: - TransactionDispatcher protocol conformance

extension PolymarketWithdrawTransactionDispatcher: TransactionDispatcher {
    var hasNFCInteraction: Bool {
        signer.hasNFCInteraction
    }

    func send(transaction: TransactionDispatcherTransactionType) async throws -> TransactionDispatcherResult {
        switch transaction {
        case .transfer(let transaction):
            return try await withdraw(
                amount: transaction.amount.value,
                destination: transaction.destinationAddress
            )

        default:
            throw TransactionDispatcherResult.Error.transactionNotFound
        }
    }
}

// MARK: - Private implementation

private extension PolymarketWithdrawTransactionDispatcher {
    func withdraw(amount: Decimal, destination: String) async throws -> TransactionDispatcherResult {
        let record = try await withdrawTransactionService.withdraw(amount: amount, to: destination)

        return TransactionDispatcherResultMapper().mapResult(
            record,
            host: PolymarketBFFEnvironment.current().baseURL.absoluteString,
            signer: signer.latestSignerType
        )
    }
}
