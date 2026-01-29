//
//  TangemPayExpressCEXTransactionProcessor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemExpress
import TangemVisa

struct TangemPayExpressCEXTransactionProcessor {
    let withdrawTransactionService: TangemPayWithdrawTransactionService
    let walletPublicKey: Wallet.PublicKey?
}

// MARK: - ExpressCEXTransactionProcessor

extension TangemPayExpressCEXTransactionProcessor: TransactionDispatcher {
    var hasNFCInteraction: Bool { true }

    func send(transaction: TransactionDispatcherTransactionType) async throws -> TransactionDispatcherResult {
        guard case .cex(let data, _) = transaction else {
            throw TransactionDispatcherResult.Error.transactionNotFound
        }

        guard let walletPublicKey else {
            throw Error.walletPublicKeyNotFound
        }

        let result = try await withdrawTransactionService.sendWithdrawTransaction(
            amount: data.txValue,
            destination: data.destinationAddress,
            walletPublicKey: walletPublicKey
        )

        return TransactionDispatcherResultMapper().mapResult(result, signer: .none)
    }
}

extension TangemPayExpressCEXTransactionProcessor {
    enum Error: LocalizedError {
        case walletPublicKeyNotFound
    }
}
