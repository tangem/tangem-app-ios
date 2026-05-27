//
//  InMemoryTransactionHistoryRecordsStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress
import TangemFoundation

// [REDACTED_TODO_COMMENT]
actor InMemoryTransactionHistoryRecordsStorage<Record: TransactionHistoryRecord> {
    private var byId: [String: Record] = [:]
    private nonisolated(unsafe) var subscribers = AsyncStream<[Record]>.Subscribers<UUID>()

    private func snapshot() -> [Record] {
        byId.values.sorted(by: { $0.updatedAt > $1.updatedAt })
    }
}

// MARK: - TransactionHistoryRecordsStorage protocol conformance

extension InMemoryTransactionHistoryRecordsStorage: TransactionHistoryRecordsStorage {
    var records: [Record] { snapshot() }

    nonisolated var recordsUpdates: AsyncStream<[Record]> {
        return AsyncStream.multicast(
            with: self,
            subscribers: \.subscribers
        ) { holder in
            holder.snapshot()
        }
    }

    func updateOrAppend(_ records: [Record]) {
        records.forEach { byId[$0.txId] = $0 }
        subscribers.yield(snapshot())
    }

    func clear() {
        byId.removeAll()
        subscribers.yield([])
    }
}
