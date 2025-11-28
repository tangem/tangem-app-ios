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
}

// MARK: - ExpressCEXTransactionProcessor

extension TangemPayExpressCEXTransactionProcessor: ExpressCEXTransactionProcessor {
    func process(data: ExpressTransactionData, fee: BSDKFee) async throws -> TransactionDispatcherResult {
        let result = try await withdrawTransactionService.sendWithdrawTransaction(
            amount: data.txValue,
            destination: data.destinationAddress
        )

        return TransactionDispatcherResultMapper().mapResult(result, signer: .none)
    }
}
