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
    private var subscribers = AsyncStream<[Record]>.Subscribers<UUID>()

    private func snapshot() -> [Record] {
        byId.values.sorted(by: { $0.updatedAt > $1.updatedAt })
    }
}

// MARK: - TransactionHistoryRecordsStorage protocol conformance

extension InMemoryTransactionHistoryRecordsStorage: TransactionHistoryRecordsStorage {
    var records: [Record] { snapshot() }

    nonisolated var recordsUpdates: AsyncStream<[Record]> {
        .multicast(
            with: self,
            onSubscribe: { storage, id, continuation in
                storage.subscribers.subscribe(id: id, continuation: continuation, currentValue: storage.snapshot())
            },
            onUnsubscribe: { storage, id in
                storage.subscribers.unsubscribe(id: id)
            }
        )
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
