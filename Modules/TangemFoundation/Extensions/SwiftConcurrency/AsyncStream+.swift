//
//  AsyncStream+.swift
//  TangemFoundation
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public extension AsyncStream {
    /// Helper that fans/multicasts a single source out to multiple
    /// subscribers of an `AsyncStream`-backed observable property.
    ///
    /// Required until `swift-async-algorithms` `share()` is implemented, see
    /// https://github.com/apple/swift-async-algorithms/blob/main/Evolution/0016-share.md for details.
    ///
    /// - Warning: Holds mutable state, so it is meant to live as isolated state of an `actor`.
    struct Subscribers {
        private var subscribers: [UUID: SubscriptionState] = [:]

        public init() {}

        public mutating func subscribe(id: UUID, continuation: Continuation, currentValue: @autoclosure () -> Element) {
            if case .cancelled = subscribers[id] {
                subscribers.removeValue(forKey: id)
                return
            }

            subscribers[id] = .active(continuation)
            continuation.yield(currentValue())
        }

        public mutating func unsubscribe(id: UUID) {
            switch subscribers[id] {
            case .active:
                subscribers.removeValue(forKey: id)
            case .none:
                subscribers[id] = .cancelled
            case .cancelled:
                break
            }
        }

        public func yield(_ element: Element) {
            for case .active(let continuation) in subscribers.values {
                continuation.yield(element)
            }
        }
    }
}

// MARK: - Auxiliary types

private extension AsyncStream.Subscribers {
    /// - Note: this tombstone-like pattern is used to prevent races between `subscribe(id:continuation:currentValue:)`
    /// and `unsubscribe(id:)` calls since their order is not guaranteed.
    enum SubscriptionState {
        case active(AsyncStream.Continuation)
        case cancelled
    }
}
