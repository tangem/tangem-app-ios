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
        let approveTransaction = approve.map { TransactionDispatcherTransactionType.approve(data: $0.data, fee: $0.fee) }
        let swapTransaction = TransactionDispatcherTransactionType.dex(data: swap.data, fee: swap.fee)
        let transactions = [approveTransaction, swapTransaction].compactMap { $0 }

        let results = try await send(transactions: transactions)
        guard let result = results.last else {
            throw TransactionDispatcherResult.Error.transactionNotFound
        }

        return result
    }
}
