//
//  MulticastObserversHelper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

/// Simple helper to implement multicast observers pattern. Useful for pollers, etc.
final class MulticastObserversHelper<Value> {
    private let state = OSAllocatedUnfairLock(initialState: State())

    @discardableResult
    func subscribe(_ handler: @escaping (Value) -> Void) -> Cancellable {
        let id = UUID()

        let latest = state { state in
            state.handlers[id] = handler

            return state.latest
        }

        // Send the latest value to the new subscriber if it exists
        if let latest {
            handler(latest)
        }

        return ThreadSafeCancellableWrapper { [weak self] in
            self?.unsubscribe(id: id)
        }
    }

    func broadcast(_ value: Value) {
        let handlers = state { state in
            state.latest = value

            return state.handlers.values
        }

        handlers.forEach { $0(value) }
    }

    private func unsubscribe(id: UUID) {
        _ = state { $0.handlers.removeValue(forKey: id) }
    }
}

// MARK: - Auxiliary types

extension MulticastObserversHelper {
    typealias Handler = (Value) -> Void

    private struct State {
        var handlers: [UUID: Handler] = [:]
        var latest: Value?
    }
}
