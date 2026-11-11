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

    init(isFailing: Bool) {
        self.isFailing = isFailing
    }

    func save(remote items: [JointOperationHistoryItem]) async throws {
        try failIfNeeded()
        state.withLock { $0.savedRemoteOperationIds.append(items.map(\.operation.id)) }
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
    }
}
