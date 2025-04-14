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
    struct AsyncMap<Upstream, Output>: Publisher where Upstream: Publisher, Upstream.Failure == Never {
        public typealias Output = Output
        public typealias Failure = Upstream.Failure
        public typealias Transform = (_ input: Upstream.Output) async -> Output

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
                .flatMap { value in
                    var task: Task<Void, Never>? = nil

                    let future = Deferred {
                        Future<Output, Never> { promise in
                            task = Task(priority: priority) {
                                guard !Task.isCancelled else { return }

                                let output = await transform(value)

                                guard !Task.isCancelled else { return }

                                promise(.success(output))
                            }
                        }
                    }

                    return future.handleEvents(receiveCancel: task?.cancel)
                }
                .receive(subscriber: subscriber)
        }
    }

    struct AsyncTryMap<Upstream, Output>: Publisher where Upstream: Publisher, Upstream.Failure == Swift.Error {
        public typealias Output = Output
        public typealias Failure = Upstream.Failure
        public typealias Transform = (_ input: Upstream.Output) async throws -> Output

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
                .flatMap { value in
                    var task: Task<Void, Never>? = nil

                    let future = Deferred {
                        Future<Output, Failure> { promise in
                            task = Task(priority: priority) {
                                guard !Task.isCancelled else { return }

                                do {
                                    let output = try await transform(value)
                                    guard !Task.isCancelled else { return }
                                    promise(.success(output))
                                } catch {
                                    guard !Task.isCancelled else { return }
                                    promise(.failure(error))
                                }
                            }
                        }
                    }

                    return future.handleEvents(receiveCancel: task?.cancel)
                }
                .receive(subscriber: subscriber)
        }
    }
}

public extension Publisher where Failure == Never {
    func asyncMap<T>(
        priority: TaskPriority? = nil,
        _ transform: @escaping (_ input: Self.Output) async -> T
    ) -> Publishers.AsyncMap<Self, T> {
        return Publishers.AsyncMap(upstream: self, priority: priority, transform: transform)
    }
}

public extension Publisher {
    func asyncTryMap<T>(
        priority: TaskPriority? = nil,
        _ transform: @escaping (_ input: Self.Output) async throws -> T
    ) -> Publishers.AsyncTryMap<Self, T> {
        return Publishers.AsyncTryMap(upstream: self, priority: priority, transform: transform)
    }
}
