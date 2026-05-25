//
//  TangemPayWithdrawSender.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemFoundation
import TangemVisa

struct TangemPayWithdrawSender {
    let withdrawTransactionService: TangemPayWithdrawTransactionService
    let walletPublicKey: Wallet.PublicKey?

    func send(amount: Decimal, destination: String) async throws -> TransactionDispatcherResult {
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

extension TangemPayWithdrawSender {
    enum Error: LocalizedError {
        case walletPublicKeyNotFound
        case transactionHashNotFound
    }

    static let interval: TimeInterval = 3
    static let initialPollingDelay: TimeInterval = 3
}
