//
//  AsyncResultPublisher.swift
//  TangemFoundation
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// Starts the work only on demand, unlike a `PassthroughSubject` (drops early results) or `Future` (loses values when fulfilled off-thread).
struct AsyncResultPublisher<Output, Failure: Error>: Publisher {
    typealias Operation = @Sendable () async -> Result<Output, Failure>

    private let priority: TaskPriority?
    private let operation: Operation

    init(priority: TaskPriority?, operation: @escaping Operation) {
        self.priority = priority
        self.operation = operation
    }

    func receive<S>(subscriber: S) where S: Subscriber, S.Input == Output, S.Failure == Failure {
        let inner = Inner(downstream: subscriber, priority: priority, operation: operation)
        subscriber.receive(subscription: inner)
    }
}

// MARK: - Private implementation

private extension AsyncResultPublisher {
    final class Inner<Downstream: Subscriber>: Subscription, @unchecked Sendable where
        Downstream.Input == Output,
        Downstream.Failure == Failure {
        private let priority: TaskPriority?
        private let operation: Operation
        private let state: OSAllocatedUnfairLock<State>

        init(downstream: Downstream, priority: TaskPriority?, operation: @escaping Operation) {
            self.priority = priority
            self.operation = operation
            state = OSAllocatedUnfairLock(uncheckedState: .awaitingDemand(downstream))
        }

        func request(_ demand: Subscribers.Demand) {
            guard demand > .none else {
                return
            }

            state { state in
                switch state {
                case .awaitingDemand(let downstream):
                    let task = Task(priority: priority) { [operation] in
                        guard !Task.isCancelled else {
                            return
                        }

                        let result = await operation()
                        self.deliver(result)
                    }
                    state = .running(downstream, task)
                case .running,
                     .finished:
                    break
                }
            }
        }

        func cancel() {
            let task: Task<Void, Never>? = state { state in
                defer {
                    state = .finished
                }

                switch state {
                case .running(_, let task):
                    return task
                case .awaitingDemand,
                     .finished:
                    return nil
                }
            }

            task?.cancel()
        }

        private func deliver(_ result: Result<Output, Failure>) {
            let downstream: Downstream? = state { state in
                switch state {
                case .running(let downstream, _):
                    state = .finished

                    return downstream
                case .awaitingDemand,
                     .finished:
                    return nil
                }
            }

            guard let downstream else {
                return
            }

            switch result {
            case .success(let output):
                _ = downstream.receive(output)
                downstream.receive(completion: .finished)
            case .failure(let error):
                downstream.receive(completion: .failure(error))
            }
        }
    }
}

// MARK: - Auxiliary types

private extension AsyncResultPublisher.Inner {
    enum State {
        case awaitingDemand(Downstream)
        case running(Downstream, Task<Void, Never>)
        case finished
    }
}
