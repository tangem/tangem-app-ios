//
//  InjectedDependenciesIsolation.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation
@testable import Tangem

/// Serializes tests that swap globals in `InjectedValues`: suites run in parallel, so without a shared
/// gate concurrent swap-and-restore sequences would observe each other's fakes. An async mutex rather
/// than a bare actor — actors are reentrant, so an actor method suspended on the operation would happily
/// interleave another caller's swap.
final class InjectedDependenciesIsolation: Sendable {
    static let shared = InjectedDependenciesIsolation()

    private let state = OSAllocatedUnfairLock(initialState: State())

    private struct State {
        var isLocked = false
        var waiters: [CheckedContinuation<Void, Never>] = []
    }

    func run<T>(_ operation: () async throws -> T) async rethrows -> T {
        await acquire()
        defer { release() }
        return try await operation()
    }

    private func acquire() async {
        await withCheckedContinuation { continuation in
            let acquired = state.withLock { state -> Bool in
                if state.isLocked {
                    state.waiters.append(continuation)
                    return false
                }

                state.isLocked = true
                return true
            }

            if acquired {
                continuation.resume()
            }
        }
    }

    private func release() {
        let next = state.withLock { state -> CheckedContinuation<Void, Never>? in
            if state.waiters.isEmpty {
                state.isLocked = false
                return nil
            }

            // Hand the lock over: `isLocked` stays true for the resumed waiter.
            return state.waiters.removeFirst()
        }

        next?.resume()
    }
}

func withInjectedTangemApiService<T>(
    _ service: TangemApiService,
    operation: () async throws -> T
) async rethrows -> T {
    try await InjectedDependenciesIsolation.shared.run {
        let previous = InjectedValues[\.tangemApiService]
        InjectedValues[\.tangemApiService] = service
        defer { InjectedValues[\.tangemApiService] = previous }
        return try await operation()
    }
}
