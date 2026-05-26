//
//  InMemoryHistoryRecordsStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

actor InMemoryHistoryRecordsStorage<Record: HistoryRecord> {
    private var byId: [String: Record] = [:]
    private var subscribers: [UUID: SubscriberState] = [:]

    init(walletAddress: String) {
        _ = walletAddress
    }

    // MARK: - Subscriber registry (tombstone pattern from `TransactionHistoryProvider`)

    private func subscribe(id: UUID, continuation: AsyncStream<[Record]>.Continuation) {
        if case .cancelled = subscribers[id] {
            subscribers.removeValue(forKey: id)
            return
        }

        subscribers[id] = .active(continuation)
        continuation.yield(snapshot())
    }

    private func unsubscribe(id: UUID) {
        switch subscribers[id] {
        case .active:
            subscribers.removeValue(forKey: id)
        case .none:
            subscribers[id] = .cancelled
        case .cancelled:
            break
        }
    }

    private func emit(_ snapshot: [Record]) {
        for case .active(let continuation) in subscribers.values {
            continuation.yield(snapshot)
        }
    }

    private func snapshot() -> [Record] {
        byId.values.sorted(by: { $0.updatedAt > $1.updatedAt })
    }
}

// MARK: - HistoryRecordsStorage protocol conformance

extension InMemoryHistoryRecordsStorage: HistoryRecordsStorage {
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
        emit(snapshot())
    }

    func clear() {
        byId.removeAll()
        emit([])
    }
}

// MARK: - Auxiliary types

private extension InMemoryHistoryRecordsStorage {
    enum SubscriberState {
        case active(AsyncStream<[Record]>.Continuation)
        case cancelled
    }
}
