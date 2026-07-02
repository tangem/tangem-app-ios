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
    struct MulticastSubscribers<ID: Hashable> {
        private var subscribers: [ID: SubscriptionState] = [:]

        public init() {}

        /// Mimics a `PassthroughSubject`: the subscriber receives only elements yielded after it subscribes.
        public mutating func subscribe(id: ID, continuation: Continuation) {
            if case .cancelled = subscribers[id] {
                subscribers.removeValue(forKey: id)
                return
            }

            subscribers[id] = .active(continuation)
        }

        /// Mimics a `CurrentValueSubject`: the subscriber receives `currentValue` immediately on subscription,
        /// then every subsequent yielded element.
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
    /// A key-path-based overload — passing `\.subscribers` instead of the `onSubscribe` / `onUnsubscribe`
    /// closures — isn't currently possible due to this Swift limitation:
    /// `You cannot  key paths to self-isolated actor properties.`
    /// See https://forums.swift.org/t/cannot-form-key-path-to-actor-isolated-property for details.
    static func multicast<Holder: Actor, ID: Hashable & Sendable>(
        with holder: Holder,
        id: ID,
        bufferingPolicy: Continuation.BufferingPolicy = .unbounded,
        onSubscribe: @escaping @Sendable (_ holder: isolated Holder, _ id: ID, _ continuation: Continuation) -> Void,
        onUnsubscribe: @escaping @Sendable (_ holder: isolated Holder, _ id: ID) -> Void
    ) -> AsyncStream<Element> {
        AsyncStream(bufferingPolicy: bufferingPolicy) { continuation in
            continuation.onTermination = { @Sendable [weak holder] _ in
                Task {
                    guard let holder else {
                        return
                    }

                    await onUnsubscribe(holder, id)
                }
            }

            Task { [weak holder] in
                guard let holder else {
                    continuation.finish()
                    return
                }

                await onSubscribe(holder, id, continuation)
            }
        }
    }

    /// A key-path-based overload — passing `\.subscribers` instead of the `onSubscribe` / `onUnsubscribe`
    /// closures — isn't currently possible due to this Swift limitation:
    /// `You cannot  key paths to self-isolated actor properties.`
    /// See https://forums.swift.org/t/cannot-form-key-path-to-actor-isolated-property for details.
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

// MARK: - Convenience extensions

public extension AsyncStream.MulticastSubscribers where Element == Void {
    func yield() {
        self.yield(())
    }
}

// MARK: - Auxiliary types

private extension AsyncStream.MulticastSubscribers {
    /// - Note: this tombstone-like pattern is used to prevent races between `subscribe(id:continuation:currentValue:)`
    /// and `unsubscribe(id:)` calls since their order is not guaranteed.
    enum SubscriptionState {
        case active(AsyncStream.Continuation)
        case cancelled
    }
}
