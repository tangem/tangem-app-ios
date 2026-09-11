//
//  TestGate.swift
//  TangemTests
//
//  Created for [REDACTED_INFO].
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// Lets a test decide when an awaited job finishes, instead of leaning on sleeps: callers park until the gate
/// opens, and everyone arriving afterwards passes straight through.
final class TestGate: @unchecked Sendable {
    private struct State {
        var isOpen = false
        var waiters: [CheckedContinuation<Void, Never>] = []
    }

    private let state = OSAllocatedUnfairLock(initialState: State())

    func wait() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let isOpen = state.withLock { state -> Bool in
                if state.isOpen {
                    return true
                }

                state.waiters.append(continuation)
                return false
            }

            if isOpen {
                continuation.resume()
            }
        }
    }

    func open() {
        let waiters = state.withLock { state -> [CheckedContinuation<Void, Never>] in
            state.isOpen = true
            let waiters = state.waiters
            state.waiters = []
            return waiters
        }

        waiters.forEach { $0.resume() }
    }
}
