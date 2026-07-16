//
//  ThreadSafeLazy.swift
//  TangemFoundation
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import os.lock

/// A thread-safe `lazy var`: the `factory` runs exactly once even under concurrent first access.
///
/// - Important: `factory` runs while the lock is held — keep it self-contained and quick, and don't
///   access this instance from within it (re-entrancy deadlocks).
public final class ThreadSafeLazy<Value> {
    private struct State {
        var value: Value?
        var factory: (() -> Value)?
    }

    private let storage: OSAllocatedUnfairLock<State>

    public init(_ factory: @escaping () -> Value) {
        storage = OSAllocatedUnfairLock(uncheckedState: State(value: nil, factory: factory))
    }

    public var value: Value {
        storage { state in
            if let value = state.value {
                return value
            }

            let created = state.factory!()
            state.value = created
            state.factory = nil
            return created
        }
    }
}
