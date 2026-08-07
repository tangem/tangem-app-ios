//
//  InMemoryTransactionHistoryRecordsStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

// [REDACTED_TODO_COMMENT]
public actor InMemoryTransactionHistoryRecordsStorage<Record: TransactionHistoryRecord> {
    private var recordsKeyedByTxId: [String: Record] = [:]
    private var subscribers = AsyncStream<[Record]>.MulticastSubscribers<UUID>()

    public init() {}

    private func makeSnapshot() -> [Record] {
        recordsKeyedByTxId.values.sorted(by: \.updatedAt)
    }
}

// MARK: - TransactionHistoryRecordsStorage protocol conformance

extension InMemoryTransactionHistoryRecordsStorage: TransactionHistoryRecordsStorage {
    public var records: [Record] { makeSnapshot() }

    public nonisolated var recordsUpdates: AsyncStream<[Record]> {
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

    public func updateOrAppend(_ records: [Record]) throws {
        records.forEach { recordsKeyedByTxId[$0.txId] = $0 }
        subscribers.yield(makeSnapshot())
    }

    public func clear() throws {
        recordsKeyedByTxId.removeAll()
        subscribers.yield(makeSnapshot())
    }
}
