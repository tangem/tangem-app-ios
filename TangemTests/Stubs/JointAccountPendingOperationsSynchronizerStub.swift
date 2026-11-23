//
//  JointAccountPendingOperationsSynchronizerStub.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
@testable import Tangem

final class JointAccountPendingOperationsSynchronizerStub: JointAccountPendingOperationsSynchronizer {
    private let pendingOperationsSubject: CurrentValueSubject<[JointAccountOperations], Never>
    private let storedOperationsSubject: CurrentValueSubject<[JointAccountOperation], Never>
    private let appliedUpdatesLock = OSAllocatedUnfairLock<[JointAccountPendingOperationsUpdate]>(initialState: [])

    var appliedUpdates: [JointAccountPendingOperationsUpdate] {
        appliedUpdatesLock.withLock { $0 }
    }

    init(pendingOperations: [JointAccountOperations] = []) {
        pendingOperationsSubject = CurrentValueSubject(pendingOperations)
        storedOperationsSubject = CurrentValueSubject(pendingOperations.flatMap(\.operations))
    }

    func store(pendingOperations: [JointAccountOperations]) {
        store(operations: pendingOperations.flatMap(\.operations))
        pendingOperationsSubject.send(pendingOperations)
    }

    func store(operations: [JointAccountOperation]) {
        let operationIds = operations.map(\.id).toSet()
        let kept = storedOperationsSubject.value.filter { !operationIds.contains($0.id) }
        storedOperationsSubject.send(kept + operations)
    }

    var pendingOperations: [JointAccountOperations] {
        pendingOperationsSubject.value
    }

    var pendingOperationsPublisher: AnyPublisher<[JointAccountOperations], Never> {
        pendingOperationsSubject.eraseToAnyPublisher()
    }

    func operationPublisher(id: String) -> AnyPublisher<JointAccountOperation?, Never> {
        storedOperationsSubject
            .map { $0.first { $0.id == id } }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var checkpoint: JointAccountPendingOperationsCheckpoint {
        JointAccountPendingOperationsCheckpoint(version: 0)
    }

    func apply(_ update: JointAccountPendingOperationsUpdate) throws {
        appliedUpdatesLock.withLock { $0.append(update) }
    }

    func apply(
        refreshedOperation operation: JointAccountOperation,
        forCryptoAccountId cryptoAccountId: String,
        requestedAt checkpoint: JointAccountPendingOperationsCheckpoint
    ) throws {
        try apply(.operationRefreshed(operation, cryptoAccountId: cryptoAccountId))
    }

    func apply(listing: [JointAccountOperations], requestedAt checkpoint: JointAccountPendingOperationsCheckpoint) throws {
        throw "Not called by these tests"
    }
}
