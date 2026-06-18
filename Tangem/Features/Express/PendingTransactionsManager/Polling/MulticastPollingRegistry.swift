//
//  MulticastPollingRegistry.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

final class MulticastPollingRegistry<Iteration> {
    private let state = OSAllocatedUnfairLock(initialState: State())

    @discardableResult
    func subscribe(_ handler: @escaping (Iteration) -> Void) -> PollingSubscription {
        let id = UUID()

        let latest = state { state in
            state.handlers[id] = handler

            return state.latest
        }

        // Send the latest iteration to the new subscriber if it exists
        if let latest {
            handler(latest)
        }

        return PollingSubscription { [weak self] in
            self?.unsubscribe(id: id)
        }
    }

    func broadcast(_ iteration: Iteration) {
        let handlers = state { state in
            state.latest = iteration

            return state.handlers.values
        }

        handlers.forEach { $0(iteration) }
    }

    private func unsubscribe(id: UUID) {
        _ = state { $0.handlers.removeValue(forKey: id) }
    }
}

// MARK: - Auxiliary types

extension MulticastPollingRegistry {
    typealias Handler = (Iteration) -> Void

    private struct State {
        var handlers: [UUID: Handler] = [:]
        var latest: Iteration?
    }
}
