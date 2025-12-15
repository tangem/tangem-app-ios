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

        return TransactionDispatcherResultMapper().mapResult(result, signer: .none)
    }
}

extension TangemPayExpressCEXTransactionProcessor {
    enum Error: LocalizedError {
        case walletPublicKeyNotFound
    }
}
