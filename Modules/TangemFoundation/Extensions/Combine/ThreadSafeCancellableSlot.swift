//
//  ThreadSafeCancellableSlot.swift
//  TangemFoundation
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// This slot provides required synchronization for a replaceable `Cancellable`, so it can be safely used from any thread.
/// `begin()` cancels the stored cancellable and returns a token for the next request.
/// `store(_:for:)` keeps a cancellable only while its token is the latest one, otherwise cancels it immediately.
/// `cancel()` cancels the stored cancellable and keeps the slot usable for the next `begin()`.
public final class ThreadSafeCancellableSlot: Sendable {
    private let state = OSAllocatedUnfairLock(uncheckedState: State())

    public init() {}

    public func begin() -> UUID {
        let token = UUID()
        reset(pendingToken: token)

        return token
    }

    public func store(_ cancellable: AnyCancellable, for token: UUID) {
        let isStored = state { state in
            guard state.pendingToken == token else {
                // The token is outdated: a later `begin()`, a `cancel()` or an earlier `store` for it has already happened
                return false
            }

            state.pendingToken = nil
            state.cancellable = cancellable

            return true
        }

        if !isStored {
            cancellable.cancel()
        }
    }

    private func reset(pendingToken: UUID?) {
        let previousCancellable = state { state in
            let previousCancellable = state.cancellable
            state.pendingToken = pendingToken
            state.cancellable = nil

            return previousCancellable
        }

        previousCancellable?.cancel()
    }
}

// MARK: - Cancellable protocol conformance

extension ThreadSafeCancellableSlot: Cancellable {
    public func cancel() {
        reset(pendingToken: nil)
    }
}

// MARK: - Convenience extensions

public extension AnyCancellable {
    func store(in slot: ThreadSafeCancellableSlot, for token: UUID) {
        slot.store(self, for: token)
    }
}

// MARK: - Auxiliary types

private extension ThreadSafeCancellableSlot {
    struct State {
        var pendingToken: UUID?
        var cancellable: AnyCancellable?
    }
}
