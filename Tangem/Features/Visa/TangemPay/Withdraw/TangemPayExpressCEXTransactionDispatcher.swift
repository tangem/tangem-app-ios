//
//  TangemPayExpressCEXTransactionDispatcher.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemExpress
import TangemVisa

struct TangemPayExpressCEXTransactionDispatcher {
    let withdrawTransactionService: TangemPayWithdrawTransactionService
    let walletPublicKey: Wallet.PublicKey?
}

// MARK: - TransactionDispatcher

extension TangemPayExpressCEXTransactionDispatcher: TransactionDispatcher {
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

        let orderResponse = try await withdrawTransactionService
            .getOrder(id: result.orderID)

        guard let txHash = orderResponse.data?.transactionHash else {
            throw Error.transactionHashNotFound
        }

        return TransactionDispatcherResultMapper().mapResult(
            result,
            txHash: txHash,
            signer: .none
        )
    }
}

extension TangemPayExpressCEXTransactionDispatcher {
    enum Error: LocalizedError {
        case walletPublicKeyNotFound
        case transactionHashNotFound
    }
}
