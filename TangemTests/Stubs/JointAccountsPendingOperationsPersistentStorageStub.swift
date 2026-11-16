//
//  JointAccountsPendingOperationsPersistentStorageStub.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
@testable import Tangem

final class JointAccountsPendingOperationsPersistentStorageStub: JointAccountsPendingOperationsPersistentStorage {
    private let state: OSAllocatedUnfairLock<State>
    private let didUpdateSubject = PassthroughSubject<Void, Never>()

    var items: [JointOperationHistoryItem] {
        state.withLock { Self.sorted($0.itemsKeyedByOperationIds.values) }
    }

    var receivedChanges: [JointAccountsPendingOperationsChanges] {
        state.withLock { $0.receivedChanges }
    }

    var didUpdatePublisher: AnyPublisher<Void, Never> {
        didUpdateSubject.eraseToAnyPublisher()
    }

    init(items: [JointOperationHistoryItem] = []) {
        state = OSAllocatedUnfairLock(initialState: State(itemsKeyedByOperationIds: items.keyedFirst(by: \.operation.id)))
    }

    func save(_ items: [JointOperationHistoryItem]) {
        state.withLock { state in
            for item in items {
                state.itemsKeyedByOperationIds[item.operation.id] = item
            }
        }

        didUpdateSubject.send()
    }

    func inFlightOperations(safeAddresses: Set<String>) throws -> [JointOperationHistoryItem] {
        items.filter { Self.isInFlight($0, at: safeAddresses) }
    }

    func operation(id: String) throws -> JointOperationHistoryItem? {
        state.withLock { $0.itemsKeyedByOperationIds[id] }
    }

    func update(
        operationIds: Set<String>,
        safeAddresses: Set<String>,
        _ resolveChanges: ([JointOperationHistoryItem]) -> JointAccountsPendingOperationsChanges
    ) throws {
        let storedItems = items.filter { operationIds.contains($0.operation.id) || Self.isInFlight($0, at: safeAddresses) }
        let changes = resolveChanges(storedItems)

        state.withLock { state in
            state.receivedChanges.append(changes)

            for operationId in changes.removedOperationIds {
                state.itemsKeyedByOperationIds[operationId] = nil
            }

            for item in changes.savedItems {
                state.itemsKeyedByOperationIds[item.operation.id] = item
            }
        }

        guard !changes.isEmpty else {
            return
        }

        didUpdateSubject.send()
    }

    private static func isInFlight(_ item: JointOperationHistoryItem, at safeAddresses: Set<String>) -> Bool {
        item.operation.finishedAt == nil && item.operation.status.isInFlight && safeAddresses.contains(item.safeAddress)
    }

    private static func sorted(_ items: some Sequence<JointOperationHistoryItem>) -> [JointOperationHistoryItem] {
        items.sorted { ($0.createdAt, $0.operation.id) < ($1.createdAt, $1.operation.id) }
    }
}

// MARK: - Auxiliary types

private extension JointAccountsPendingOperationsPersistentStorageStub {
    struct State {
        var itemsKeyedByOperationIds: [String: JointOperationHistoryItem]
        var receivedChanges: [JointAccountsPendingOperationsChanges] = []
    }
}
