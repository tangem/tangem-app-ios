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
        guard let approve else {
            // Legacy path — a single swap transaction (incl. non-EVM DEX like Solana)
            return try await send(transaction: .dex(data: swap.data, fee: swap.fee))
        }

        // The displayed fee is the approve+swap total — the swap tx itself goes out with its own component.
        guard let combinedFeeParameters = swap.fee.parameters as? ApproveWithSwapFeeParameters else {
            throw TransactionDispatcherResult.Error.feeNotFound
        }

        let swapTransactionFee = combinedFeeParameters.swapFee(total: swap.fee)
        let transactions: [TransactionDispatcherTransactionType] = [
            .approve(data: approve.data, fee: approve.fee),
            .dex(data: swap.data, fee: swapTransactionFee),
        ]

        let results = try await send(transactions: transactions)
        guard let result = results.last else {
            throw TransactionDispatcherResult.Error.transactionNotFound
        }

        return result
    }
}
