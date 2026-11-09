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
    private let pendingOperationsSubject: CurrentValueSubject<[StoredJointAccountPendingOperations], Never>
    private let appliedUpdatesLock = OSAllocatedUnfairLock<[JointAccountPendingOperationsUpdate]>(initialState: [])

    var appliedUpdates: [JointAccountPendingOperationsUpdate] {
        appliedUpdatesLock.withLock { $0 }
    }

    init(pendingOperations: [StoredJointAccountPendingOperations] = []) {
        pendingOperationsSubject = CurrentValueSubject(pendingOperations)
    }

    func store(pendingOperations: [StoredJointAccountPendingOperations]) {
        pendingOperationsSubject.send(pendingOperations)
    }

    var operations: [StoredJointAccountPendingOperations] {
        pendingOperationsSubject.value
    }

    var operationsPublisher: AnyPublisher<[StoredJointAccountPendingOperations], Never> {
        pendingOperationsSubject.eraseToAnyPublisher()
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

    func apply(listing: [StoredJointAccountPendingOperations], requestedAt checkpoint: JointAccountPendingOperationsCheckpoint) throws {
        throw "Not called by these tests"
    }
}
