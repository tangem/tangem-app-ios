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
        public typealias Transform = @Sendable (_ input: Upstream.Output) async -> Output

        private let upstream: Upstream
        private let priority: TaskPriority?
        private let transform: Transform

        fileprivate init(upstream: Upstream, priority: TaskPriority?, transform: @escaping Transform) {
            self.upstream = upstream
            self.priority = priority
            self.transform = transform
        }

        public func receive<S>(subscriber: S) where S: Subscriber, Upstream.Failure == S.Failure, Output == S.Input {
            upstream
                .flatMap(maxPublishers: .max(1)) { [priority, transform] value in
                    AsyncResultPublisher<Output, Failure>(priority: priority) {
                        let output = await transform(value)

                        return .success(output)
                    }
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
