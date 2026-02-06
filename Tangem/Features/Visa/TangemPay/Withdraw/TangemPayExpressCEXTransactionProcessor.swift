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

extension TangemPayExpressCEXTransactionProcessor: ExpressCEXTransactionProcessor {
    func process(data: ExpressTransactionData, fee: BSDKFee) async throws -> TransactionDispatcherResult {
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

extension TangemPayExpressCEXTransactionProcessor {
    enum Error: LocalizedError {
        case walletPublicKeyNotFound
        case transactionHashNotFound
    }
}
