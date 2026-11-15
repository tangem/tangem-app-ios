//
//  JointOperationsHistoryWriterStub.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
@testable import Tangem

final class JointOperationsHistoryWriterStub: JointOperationsHistoryWriter {
    private let isFailing: Bool
    private let state = OSAllocatedUnfairLock(initialState: State())

    var savedRemoteOperationIds: [[String]] {
        state.withLock { $0.savedRemoteOperationIds }
    }

    var savedLocalItems: [[JointOperationHistoryItem]] {
        state.withLock { $0.savedLocalItems }
    }

    var deletedOperationIds: [[String]] {
        state.withLock { $0.deletedOperationIds }
    }

    init(isFailing: Bool) {
        self.isFailing = isFailing
    }

    func save(remote items: [JointOperationHistoryItem]) async throws {
        try failIfNeeded()
        state.withLock { $0.savedRemoteOperationIds.append(items.map(\.operation.id)) }
    }

    func save(local items: [JointOperationHistoryItem]) async throws {
        try failIfNeeded()
        state.withLock { $0.savedLocalItems.append(items) }
    }

    func delete(operationIds: [String]) async throws {
        try failIfNeeded()
        state.withLock { $0.deletedOperationIds.append(operationIds) }
    }

    private func failIfNeeded() throws {
        guard !isFailing else {
            throw "The database refused the write"
        }
    }
}

// MARK: - Auxiliary types

private extension JointOperationsHistoryWriterStub {
    struct State {
        var savedRemoteOperationIds: [[String]] = []
        var savedLocalItems: [[JointOperationHistoryItem]] = []
        var deletedOperationIds: [[String]] = []
    }
}
