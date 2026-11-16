//
//  PolymarketTestGate.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

final class PolymarketTestGate: Sendable {
    let entered = TestSignal<Void>()
    let cancelled = TestSignal<Void>()

    private let state = OSAllocatedUnfairLock(initialState: State())

    var isOpen: Bool {
        state.withLock { $0.isOpen }
    }

    init(isOpen: Bool = false) {
        state.withLock { $0.isOpen = isOpen }
    }

    @MainActor
    func pass() async {
        entered.send()

        await withTaskCancellationHandler {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                let passesNow = state.withLock { state -> Bool in
                    guard !state.isOpen else { return true }

                    state.waiters.append(continuation)
                    return false
                }

                if passesNow {
                    continuation.resume()
                }
            }
        } onCancel: {
            cancelled.send()
        }
    }

    func open() {
        let waiters = state.withLock { state -> [CheckedContinuation<Void, Never>] in
            state.isOpen = true
            defer { state.waiters.removeAll() }
            return state.waiters
        }

        waiters.forEach { $0.resume() }
    }

    func releaseWaiting() {
        let waiters = state.withLock { state -> [CheckedContinuation<Void, Never>] in
            defer { state.waiters.removeAll() }
            return state.waiters
        }

        waiters.forEach { $0.resume() }
    }

    private struct State {
        var isOpen = false
        var waiters: [CheckedContinuation<Void, Never>] = []
    }
}
