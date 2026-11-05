//
//  JointOperationsSyncMetadataStorageStub.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
@testable import Tangem

final class JointOperationsSyncMetadataStorageStub: JointOperationsSyncMetadataStorage {
    private struct State {
        var archiveCursor: String?
        var deltaCursor: String?
        var isInitialSyncDone = false
        var clearCallsCount = 0
    }

    private let state: OSAllocatedUnfairLock<State>
    private let isDeltaCursorWriteFailing: Bool

    var archiveCursorValue: String? {
        state.withLock(\.archiveCursor)
    }

    var deltaCursorValue: String? {
        state.withLock(\.deltaCursor)
    }

    var isInitialSyncDoneValue: Bool {
        state.withLock(\.isInitialSyncDone)
    }

    var clearCallsCount: Int {
        state.withLock(\.clearCallsCount)
    }

    init(archiveCursor: String?, deltaCursor: String?, isInitialSyncDone: Bool = false, isDeltaCursorWriteFailing: Bool = false) {
        self.isDeltaCursorWriteFailing = isDeltaCursorWriteFailing
        state = OSAllocatedUnfairLock(initialState: State(
            archiveCursor: archiveCursor,
            deltaCursor: deltaCursor,
            isInitialSyncDone: isInitialSyncDone
        ))
    }

    func archiveCursor() async throws -> String? {
        state.withLock(\.archiveCursor)
    }

    func setArchiveCursor(_ cursor: String?) async throws {
        state.withLock { $0.archiveCursor = cursor }
    }

    func deltaCursor() async throws -> String? {
        state.withLock(\.deltaCursor)
    }

    func setDeltaCursor(_ cursor: String?) async throws {
        guard !isDeltaCursorWriteFailing else {
            throw "The database refused the delta cursor"
        }

        state.withLock { $0.deltaCursor = cursor }
    }

    func isInitialSyncDone() async throws -> Bool {
        state.withLock(\.isInitialSyncDone)
    }

    func setIsInitialSyncDone(_ isDone: Bool) async throws {
        state.withLock { $0.isInitialSyncDone = isDone }
    }

    func clear() async throws {
        state.withLock { state in
            state.archiveCursor = nil
            state.deltaCursor = nil
            state.isInitialSyncDone = false
            state.clearCallsCount += 1
        }
    }
}
