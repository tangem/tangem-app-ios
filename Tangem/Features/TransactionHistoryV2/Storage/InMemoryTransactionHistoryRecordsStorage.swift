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
    private var subscribers = AsyncStream<[Record]>.Subscribers()

    private func subscribe(id: UUID, continuation: AsyncStream<[Record]>.Continuation) {
        subscribers.subscribe(id: id, continuation: continuation, currentValue: snapshot())
    }

    private func unsubscribe(id: UUID) {
        subscribers.unsubscribe(id: id)
    }

    private func snapshot() -> [Record] {
        byId.values.sorted(by: { $0.updatedAt > $1.updatedAt })
    }
}

// MARK: - TransactionHistoryRecordsStorage protocol conformance

extension InMemoryTransactionHistoryRecordsStorage: TransactionHistoryRecordsStorage {
    var records: [Record] { snapshot() }

    nonisolated var recordsUpdates: AsyncStream<[Record]> {
        AsyncStream(bufferingPolicy: .bufferingNewest(1)) { [weak self] continuation in
            let subscriberId = UUID()

            continuation.onTermination = { @Sendable [weak self] _ in
                guard let self else {
                    return
                }

                Task {
                    await self.unsubscribe(id: subscriberId)
                }
            }

            Task { [weak self] in
                guard let self else {
                    continuation.finish()
                    return
                }

                await subscribe(id: subscriberId, continuation: continuation)
            }
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
