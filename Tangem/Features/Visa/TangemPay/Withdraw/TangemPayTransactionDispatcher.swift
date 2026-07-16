//
//  TangemPayTransactionDispatcher.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemFoundation
import TangemVisa

struct TangemPayTransactionDispatcher {
    let withdrawTransactionService: TangemPayWithdrawTransactionService
    let hasNFCInteraction: Bool
    let walletPublicKey: Wallet.PublicKey?
}

// MARK: - TransactionDispatcher

extension TangemPayTransactionDispatcher: TransactionDispatcher {
    func send(transaction: TransactionDispatcherTransactionType) async throws -> TransactionDispatcherResult {
        switch transaction {
        case .transfer(let transaction):
            return try await sendWithdraw(
                amount: transaction.amount.value,
                destination: transaction.destinationAddress
            )

        case .cex(let data, _):
            return try await sendWithdraw(
                amount: data.txValue,
                destination: data.destinationAddress
            )

        default:
            throw TransactionDispatcherResult.Error.transactionNotFound
        }
    }
}

// MARK: - Private

private extension TangemPayTransactionDispatcher {
    func sendWithdraw(amount: Decimal, destination: String) async throws -> TransactionDispatcherResult {
        guard let walletPublicKey else {
            throw Error.walletPublicKeyNotFound
        }

        let result = try await withdrawTransactionService.sendWithdrawTransaction(
            amount: amount,
            destination: destination,
            walletPublicKey: walletPublicKey
        )

        // The server needs a moment to produce a transaction hash before polling can pick it up.
        try? await Task.sleep(for: .seconds(Self.initialPollingDelay))

        let pollingSequence = PollingSequence(
            interval: Self.interval,
            request: { [withdrawTransactionService] in
                try await withdrawTransactionService.getOrder(id: result.orderID)
            }
        )

        let txHash = await pollingSequence
            .prefix(5)
            .first(where: { $0.value?.data?.transactionHash != nil })?
            .value?
            .data?
            .transactionHash

        guard let txHash else {
            throw Error.transactionHashNotFound
        }

        return TransactionDispatcherResultMapper().mapResult(
            result,
            txHash: txHash,
            signer: .none
        )
    }
}

// MARK: - Error / Constants

extension TangemPayTransactionDispatcher {
    enum Error: LocalizedError {
        case walletPublicKeyNotFound
        case transactionHashNotFound
    }

    static let interval: TimeInterval = 3
    static let initialPollingDelay: TimeInterval = 3
}
