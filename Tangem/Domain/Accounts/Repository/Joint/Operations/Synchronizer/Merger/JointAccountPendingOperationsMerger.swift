//
//  JointAccountPendingOperationsMerger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct JointAccountPendingOperationsMerger {
    private let dateProvider: DateProvider
    private let finishedOperationChecker = JointAccountFinishedOperationChecker()

    init(dateProvider: DateProvider = SystemDateProvider()) {
        self.dateProvider = dateProvider
    }

    func merge(
        listing: [JointAccountOperations],
        into stored: [JointAccountOperations],
        replaying updates: [JointAccountPendingOperationsUpdate]
    ) -> [JointAccountOperations] {
        let now = dateProvider.now

        return updates.reduce(merge(listing: listing, into: stored, now: now)) { merged, update in
            merge(merged, applying: update, now: now)
        }
    }

    func merge(
        _ stored: [JointAccountOperations],
        applying update: JointAccountPendingOperationsUpdate
    ) -> [JointAccountOperations] {
        merge(stored, applying: update, now: dateProvider.now)
    }
}

// MARK: - Private

private extension JointAccountPendingOperationsMerger {
    func merge(
        _ stored: [JointAccountOperations],
        applying update: JointAccountPendingOperationsUpdate,
        now: Date
    ) -> [JointAccountOperations] {
        switch update {
        case .localOperation(let operation, let cryptoAccountId):
            upsert(operation, forCryptoAccountId: cryptoAccountId, in: stored, now: now)
        case .operationAdded(let operation, let cryptoAccountId):
            add(operation, forCryptoAccountId: cryptoAccountId, to: stored, now: now)
        case .operationRefreshed(let operation, let cryptoAccountId):
            refresh(operation, forCryptoAccountId: cryptoAccountId, in: stored, now: now)
        case .operationRemoved(let id, let cryptoAccountId):
            remove(operationWithId: id, forCryptoAccountId: cryptoAccountId, from: stored)
        }
    }

    func merge(
        listing: [JointAccountOperations],
        into stored: [JointAccountOperations],
        now: Date
    ) -> [JointAccountOperations] {
        var merged = stored

        for record in listing {
            for operation in record.operations where !finishedOperationChecker.isFinished(operation) {
                merged = merge(merged, applying: .operationAdded(operation, cryptoAccountId: record.cryptoAccountId), now: now)
            }
        }

        return merged
    }

    func upsert(
        _ operation: JointAccountOperation,
        forCryptoAccountId cryptoAccountId: String,
        in stored: [JointAccountOperations],
        now: Date
    ) -> [JointAccountOperations] {
        edit(operationsForCryptoAccountId: cryptoAccountId, in: stored) { operations in
            // Updated in place, so that the order the listing reported survives an answer to one of them
            if let index = operations.firstIndex(where: { $0.id == operation.id }) {
                operations[index] = resolve(stored: operations[index], incoming: operation, now: now)
            } else {
                operations.append(stamped(operation, finishedAt: now))
            }
        }
    }

    func add(
        _ operation: JointAccountOperation,
        forCryptoAccountId cryptoAccountId: String,
        to stored: [JointAccountOperations],
        now: Date
    ) -> [JointAccountOperations] {
        let isStored = stored.first(by: cryptoAccountId)?.operations.contains { $0.id == operation.id } == true

        guard !isStored else {
            return stored
        }

        return upsert(operation, forCryptoAccountId: cryptoAccountId, in: stored, now: now)
    }

    func refresh(
        _ operation: JointAccountOperation,
        forCryptoAccountId cryptoAccountId: String,
        in stored: [JointAccountOperations],
        now: Date
    ) -> [JointAccountOperations] {
        let isStored = stored.first(by: cryptoAccountId)?.operations.contains { $0.id == operation.id } == true

        guard isStored || finishedOperationChecker.isFinished(operation) else {
            return stored
        }

        return upsert(operation, forCryptoAccountId: cryptoAccountId, in: stored, now: now)
    }

    func resolve(stored: JointAccountOperation, incoming: JointAccountOperation, now: Date) -> JointAccountOperation {
        if finishedOperationChecker.isFinished(stored), !finishedOperationChecker.isFinished(incoming) {
            return stored
        }

        return stamped(incoming, finishedAt: stored.finishedAt ?? now)
    }

    func stamped(_ operation: JointAccountOperation, finishedAt: Date) -> JointAccountOperation {
        guard finishedOperationChecker.isFinished(operation), operation.finishedAt == nil else {
            return operation
        }

        return operation.settingFinishedAt(finishedAt)
    }

    func remove(
        operationWithId operationId: String,
        forCryptoAccountId cryptoAccountId: String,
        from stored: [JointAccountOperations]
    ) -> [JointAccountOperations] {
        edit(operationsForCryptoAccountId: cryptoAccountId, in: stored) { operations in
            operations.removeAll { $0.id == operationId }
        }
    }

    /// - Note: An account left with no operations keeps no record, the way a listing reporting none writes none.
    func edit(
        operationsForCryptoAccountId cryptoAccountId: String,
        in stored: [JointAccountOperations],
        _ edit: (inout [JointAccountOperation]) -> Void
    ) -> [JointAccountOperations] {
        let index = stored.firstIndex(by: cryptoAccountId)
        var operations = index.map { stored[$0].operations } ?? []
        edit(&operations)

        var records = stored

        switch (index, operations.isEmpty) {
        case (let index?, true):
            records.remove(at: index)
        case (let index?, false):
            records[index] = JointAccountOperations(cryptoAccountId: stored[index].cryptoAccountId, operations: operations)
        case (nil, true):
            break
        case (nil, false):
            records.append(JointAccountOperations(cryptoAccountId: cryptoAccountId, operations: operations))
        }

        return records
    }
}
