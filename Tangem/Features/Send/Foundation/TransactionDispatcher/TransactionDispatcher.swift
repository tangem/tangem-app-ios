//
//  TransactionDispatcher.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemExpress
import TangemFoundation

protocol TransactionDispatcher {
    var hasNFCInteraction: Bool { get }

    func send(transaction: TransactionDispatcherTransactionType) async throws -> TransactionDispatcherResult
    func send(transactions: [TransactionDispatcherTransactionType]) async throws -> [TransactionDispatcherResult]

    func sendDexSwap(
        swap: (data: ExpressTransactionData, fee: BSDKFee),
        approve: (data: ApproveTransactionData, fee: BSDKFee)?
    ) async throws -> TransactionDispatcherResult
}

extension TransactionDispatcher {
    func send(transactions: [TransactionDispatcherTransactionType]) async throws -> [TransactionDispatcherResult] {
        try await transactions.asyncMap { transaction in
            try await send(transaction: transaction)
        }
    }

    func sendDexSwap(
        swap: (data: ExpressTransactionData, fee: BSDKFee),
        approve: (data: ApproveTransactionData, fee: BSDKFee)?
    ) async throws -> TransactionDispatcherResult {
        // The displayed fee is the approve+swap total — the swap tx itself goes out with its own component.
        let swapTransactionFee: BSDKFee
        if let combinedFeeParameters = swap.fee.parameters as? ApproveWithSwapFeeParameters {
            swapTransactionFee = combinedFeeParameters.swapFee(total: swap.fee)
        } else if approve != nil {
            // One-tap send requires the combined fee shape — refuse to send with an inconsistent split.
            throw TransactionDispatcherResult.Error.feeNotFound
        } else {
            swapTransactionFee = swap.fee
        }

        let approveTransaction = approve.map { TransactionDispatcherTransactionType.approve(data: $0.data, fee: $0.fee) }
        let swapTransaction = TransactionDispatcherTransactionType.dex(data: swap.data, fee: swapTransactionFee)
        let transactions = [approveTransaction, swapTransaction].compactMap { $0 }

        let results = try await send(transactions: transactions)
        guard let result = results.last else {
            throw TransactionDispatcherResult.Error.transactionNotFound
        }

        return result
    }
}
