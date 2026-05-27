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
    struct Subscribers<ID: Hashable> {
        private var subscribers: [ID: SubscriptionState] = [:]

        public init() {}

        public mutating func subscribe(id: ID, continuation: Continuation, currentValue: @autoclosure () -> Element) {
            if case .cancelled = subscribers[id] {
                subscribers.removeValue(forKey: id)
                return
            }

            subscribers[id] = .active(continuation)
            continuation.yield(currentValue())
        }

        public mutating func unsubscribe(id: ID) {
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

public extension AsyncStream {
    static func multicast<Holder: Actor, ID: Hashable & Sendable>(
        with holder: Holder,
        id: ID,
        subscribers: ReferenceWritableKeyPath<Holder, Subscribers<ID>>,
        bufferingPolicy: Continuation.BufferingPolicy = .unbounded,
        currentValue: @escaping (_ holder: isolated Holder) -> Element
    ) -> AsyncStream<Element> {
        AsyncStream(bufferingPolicy: bufferingPolicy) { [weak holder] continuation in
            continuation.onTermination = { @Sendable _ in
                guard let holder else {
                    return
                }

                Task {
                    await holder.performIsolated { _holder in
                        _holder[keyPath: subscribers].unsubscribe(id: id)
                    }
                }
            }

            Task {
                guard let holder else {
                    continuation.finish()
                    return
                }

                await holder.performIsolated { _holder in
                    _holder[keyPath: subscribers].subscribe(
                        id: id,
                        continuation: continuation,
                        currentValue: currentValue(_holder)
                    )
                }
            }
        }
    }

    static func multicast<Holder: Actor>(
        with holder: Holder,
        subscribers: ReferenceWritableKeyPath<Holder, Subscribers<UUID>>,
        bufferingPolicy: Continuation.BufferingPolicy = .unbounded,
        currentValue: @escaping (_ holder: isolated Holder) -> Element
    ) -> AsyncStream<Element> {
        multicast(
            with: holder,
            id: UUID(),
            subscribers: subscribers,
            bufferingPolicy: bufferingPolicy,
            currentValue: currentValue
        )
    }

    static func multicast<Holder: Actor, ID: Hashable & Sendable>(
        with holder: Holder,
        id: ID,
        bufferingPolicy: Continuation.BufferingPolicy = .unbounded,
        onSubscribe: @escaping @Sendable (_ holder: isolated Holder, _ id: ID, _ continuation: Continuation) -> Void,
        onUnsubscribe: @escaping @Sendable (_ holder: isolated Holder, _ id: ID) -> Void
    ) -> AsyncStream<Element> {
        AsyncStream(bufferingPolicy: bufferingPolicy) { [weak holder] continuation in
            continuation.onTermination = { @Sendable _ in
                guard let holder else {
                    return
                }

                Task {
                    await onUnsubscribe(holder, id)
                }
            }

            Task {
                guard let holder else {
                    continuation.finish()
                    return
                }

                await onSubscribe(holder, id, continuation)
            }
        }
    }

    static func multicast<Holder: Actor>(
        with holder: Holder,
        bufferingPolicy: Continuation.BufferingPolicy = .unbounded,
        onSubscribe: @escaping @Sendable (_ holder: isolated Holder, _ id: UUID, _ continuation: Continuation) -> Void,
        onUnsubscribe: @escaping @Sendable (_ holder: isolated Holder, _ id: UUID) -> Void
    ) -> AsyncStream<Element> {
        multicast(
            with: holder,
            id: UUID(),
            bufferingPolicy: bufferingPolicy,
            onSubscribe: onSubscribe,
            onUnsubscribe: onUnsubscribe
        )
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
