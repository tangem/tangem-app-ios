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
import TangemFoundation

protocol TransactionDispatcher {
    var hasNFCInteraction: Bool { get }

    func send(transaction: TransactionDispatcherTransactionType) async throws -> TransactionDispatcherResult
    func send(transactions: [TransactionDispatcherTransactionType]) async throws -> [TransactionDispatcherResult]
}

extension TransactionDispatcher {
    func send(transactions: [TransactionDispatcherTransactionType]) async throws -> [TransactionDispatcherResult] {
        try await transactions.asyncMap { transaction in
            try await send(transaction: transaction)
        }
    }
}
