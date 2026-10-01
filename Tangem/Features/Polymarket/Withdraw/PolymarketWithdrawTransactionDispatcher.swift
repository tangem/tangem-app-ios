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
        guard case .transfer(let transfer) = transaction else {
            throw TransactionDispatcherResult.Error.transactionNotFound
        }

        let mapper = TransactionDispatcherResultMapper()

        do {
            let record = try await withdrawTransactionService.withdraw(
                amount: transfer.amount.value,
                to: transfer.destinationAddress
            )

            return mapper.mapResult(
                record,
                host: PolymarketBFFEnvironment.current().baseURL.absoluteString,
                signer: signer.latestSignerType
            )
        } catch {
            throw mapper.mapError(error.toUniversalError(), transaction: transaction)
        }
    }
}
