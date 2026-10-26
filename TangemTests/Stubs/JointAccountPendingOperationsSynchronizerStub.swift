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
    let pendingOperations: [StoredJointAccountPendingOperations]
    private let appliedUpdatesLock = OSAllocatedUnfairLock<[JointAccountPendingOperationsUpdate]>(initialState: [])

    var appliedUpdates: [JointAccountPendingOperationsUpdate] {
        appliedUpdatesLock.withLock { $0 }
    }

    init(pendingOperations: [StoredJointAccountPendingOperations] = []) {
        self.pendingOperations = pendingOperations
    }

    var pendingOperationsPublisher: AnyPublisher<[StoredJointAccountPendingOperations], Never> {
        Just(pendingOperations).eraseToAnyPublisher()
    }

    var checkpoint: JointAccountPendingOperationsCheckpoint {
        JointAccountPendingOperationsCheckpoint(version: 0)
    }

    func apply(_ update: JointAccountPendingOperationsUpdate) throws {
        appliedUpdatesLock.withLock { $0.append(update) }
    }

    func apply(listing: [StoredJointAccountPendingOperations], requestedAt checkpoint: JointAccountPendingOperationsCheckpoint) throws {
        throw "Not called by these tests"
    }
}
