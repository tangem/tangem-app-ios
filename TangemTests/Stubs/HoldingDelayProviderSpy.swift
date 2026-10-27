//
//  HoldingDelayProviderSpy.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

final class HoldingDelayProviderSpy: PollDelayProvider {
    var heldWaits: [TimeInterval] { state.withLock { $0.heldWaits } }

    private let holdThreshold: TimeInterval
    private let state = OSAllocatedUnfairLock(initialState: State())

    init(holdThreshold: TimeInterval = 3) {
        self.holdThreshold = holdThreshold
    }

    func wait(for seconds: TimeInterval) async throws {
        guard seconds > holdThreshold else { return }

        let id = UUID()
        state.withLock { $0.heldWaits.append(seconds) }

        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                let resumesNow = state.withLock { state -> Bool in
                    guard !state.isReleased, !Task.isCancelled else { return true }

                    state.parked[id] = continuation
                    return false
                }

                if resumesNow {
                    continuation.resume()
                }
            }
        } onCancel: {
            state.withLock { $0.parked.removeValue(forKey: id) }?.resume(throwing: CancellationError())
        }
    }

    func releaseHeldWaits() {
        let parked = state.withLock { state -> [CheckedContinuation<Void, Error>] in
            state.isReleased = true
            defer { state.parked.removeAll() }
            return Array(state.parked.values)
        }

        parked.forEach { $0.resume() }
    }

    private struct State {
        var heldWaits: [TimeInterval] = []
        var parked: [UUID: CheckedContinuation<Void, Error>] = [:]
        var isReleased = false
    }
}
