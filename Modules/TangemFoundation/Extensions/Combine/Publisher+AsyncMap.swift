//
//  Publisher+AsyncMap.swift
//  TangemFoundation
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

public extension Publishers {
    struct AsyncMap<Upstream, Output>: Publisher where Upstream: Publisher {
        public typealias Output = Output
        public typealias Failure = Upstream.Failure
        public typealias Transform = (_ input: Upstream.Output) async -> Output

        private let upstream: Upstream
        private let priority: TaskPriority?
        private let transform: Transform

        fileprivate init(upstream: Upstream, priority: TaskPriority?, transform: @escaping @Sendable Transform) {
            self.upstream = upstream
            self.priority = priority
            self.transform = transform
        }

        public func receive<S>(subscriber: S) where S: Subscriber, Upstream.Failure == S.Failure, Output == S.Input {
            upstream
                .flatMap(maxPublishers: .max(1)) { value in
                    let subject = PassthroughSubject<Output, Failure>()

                    let task = Task(priority: priority) {
                        // This defer handles task cancellation (`guard !Task.isCancelled else { return }` checks below
                        // Only the very first `completion` call will be sent to the subscriber
                        defer { subject.send(completion: .finished) }

                        guard !Task.isCancelled else { return }

                        let output = await transform(value)

                        guard !Task.isCancelled else { return }

                        subject.send(output)
                        subject.send(completion: .finished)
                    }

                    return subject.handleEvents(receiveCancel: task.cancel)
                }
                .receive(subscriber: subscriber)
        }
    }
}

public extension Publisher {
    func asyncMap<T>(
        priority: TaskPriority? = nil,
        _ transform: @escaping @Sendable (_ input: Self.Output) async -> T
    ) -> Publishers.AsyncMap<Self, T> {
        return Publishers.AsyncMap(upstream: self, priority: priority, transform: transform)
    }
}
