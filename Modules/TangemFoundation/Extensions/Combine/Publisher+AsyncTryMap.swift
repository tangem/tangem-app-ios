//
//  Publisher+AsyncTryMap.swift
//  TangemFoundation
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

public extension Publishers {
    struct AsyncTryMap<Upstream, Output>: Publisher where Upstream: Publisher, Upstream.Failure == Swift.Error {
        public typealias Output = Output
        public typealias Failure = Upstream.Failure
        public typealias Transform = @Sendable (_ input: Upstream.Output) async throws -> Output

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
                        do {
                            let output = try await transform(value)

                            return .success(output)
                        } catch {
                            return .failure(error)
                        }
                    }
                }
                .receive(subscriber: subscriber)
        }
    }
}

public extension Publisher {
    func asyncTryMap<T>(
        priority: TaskPriority? = nil,
        _ transform: @escaping @Sendable (_ input: Self.Output) async throws -> T
    ) -> Publishers.AsyncTryMap<Self, T> where Self.Failure == Swift.Error {
        return Publishers.AsyncTryMap(upstream: self, priority: priority, transform: transform)
    }
}
