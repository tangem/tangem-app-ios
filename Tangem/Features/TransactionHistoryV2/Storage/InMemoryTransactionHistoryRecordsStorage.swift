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
    private var recordsKeyedByTxId: [String: Record] = [:]
    private var subscribers = AsyncStream<[Record]>.MulticastSubscribers<UUID>()

    private func makeSnapshot() -> [Record] {
        recordsKeyedByTxId.values.sorted(by: \.updatedAt)
    }
}

// MARK: - TransactionHistoryRecordsStorage protocol conformance

extension InMemoryTransactionHistoryRecordsStorage: TransactionHistoryRecordsStorage {
    var records: [Record] { makeSnapshot() }

    nonisolated var recordsUpdates: AsyncStream<[Record]> {
        .multicast(
            with: self,
            onSubscribe: { storage, id, continuation in
                storage.subscribers.subscribe(id: id, continuation: continuation, currentValue: storage.makeSnapshot())
            },
            onUnsubscribe: { storage, id in
                storage.subscribers.unsubscribe(id: id)
            }
        )
    }

    func updateOrAppend(_ records: [Record]) throws {
        records.forEach { recordsKeyedByTxId[$0.txId] = $0 }
        subscribers.yield(makeSnapshot())
    }

    func clear() throws {
        recordsKeyedByTxId.removeAll()
        subscribers.yield(makeSnapshot())
    }
}
