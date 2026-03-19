//
//  Task+Timeout.swift
//  TangemFoundation
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import class Combine.AnyCancellable

public extension Task where Failure == Error {
    @discardableResult
    static func run<C>(
        withTimeout timeout: C.Instant.Duration,
        tolerance: C.Instant.Duration? = nil,
        clock: C = .continuous,
        code: @escaping @Sendable () async throws -> Success,
        onTimeout: @escaping @Sendable () -> Void = {}
    ) -> Task<Success, Error> where Success: Sendable, C: Clock {
        Task {
            do {
                return try await run(withTimeout: timeout, tolerance: tolerance, clock: clock, code: code)
            } catch let error as TaskTimeoutError {
                onTimeout()
                throw error
            } catch {
                throw error
            }
        }
    }

    static func run<C>(
        withTimeout timeout: C.Instant.Duration,
        tolerance: C.Instant.Duration? = nil,
        clock: C = .continuous,
        code: @escaping @Sendable () async throws -> Success
    ) async throws -> Success where Success: Sendable, C: Clock {
        let taskCancellableWrapper = ThreadSafeCancellableWrapper()
        let continuationCancellableWrapper = ThreadSafeCancellableWrapper()

        // This `withTaskCancellationHandler` scope is absolutely necessary to propagate cancellation from the parent task.
        return try await withTaskCancellationHandler {
            // This `withCheckedThrowingContinuation` scope is absolutely necessary because Swift Concurrency task group
            // does not return early after the single `await taskGroup.nextResult()` call.
            // The task group will always wait for all child tasks to finish before it ends therefore we use Continuation API
            // to resume the parent task as soon as one of the child tasks finishes and then cancel the other one.
            // See https://forums.swift.org/t/running-an-async-task-with-a-timeout/49733/15 and other posts in that thread for more details.
            return try await withCheckedThrowingContinuation { continuation in
                let continuationWrapper = ResumableOnceCheckedContinuationWrapper(continuation)

                // Prevents a potential race condition when Combine subscription is cancelled
                // immediately after creation (race between `onCancel` and `.store()` calls).
                // Without it, the cancellation may leak without resuming the continuation, which ultimately will hang the task.
                continuationCancellableWrapper.set(
                    AnyCancellable { continuationWrapper.resumeIfNeeded(throwing: _Concurrency.CancellationError()) }
                )

                // This check is necessary in case this code runs after the task was
                // cancelled. In which case we want to bail right away.
                guard !Task<Never, Never>.isCancelled else {
                    continuationWrapper.resumeIfNeeded(throwing: _Concurrency.CancellationError())
                    return
                }

                Task<Void, Never> {
                    await withTaskGroup(of: Void.self) { taskGroup in
                        defer { taskGroup.cancelAll() }

                        taskGroup.addTask {
                            do {
                                let result = try await code()
                                continuationWrapper.resumeIfNeeded(returning: result)
                            } catch {
                                continuationWrapper.resumeIfNeeded(throwing: error)
                            }
                        }

                        taskGroup.addTask {
                            do {
                                try await Task<Never, Never>.sleep(for: timeout, tolerance: tolerance, clock: clock)
                                try Task<Never, Never>.checkCancellation()
                                continuationWrapper.resumeIfNeeded(throwing: TaskTimeoutError())
                            } catch {
                                continuationWrapper.resumeIfNeeded(throwing: error)
                            }
                        }

                        let _ = await taskGroup.next()
                    }
                }.eraseToAnyCancellable().store(in: taskCancellableWrapper)
            }
        } onCancel: {
            taskCancellableWrapper.cancel()
            continuationCancellableWrapper.cancel()
        }
    }
}

// MARK: - Auxiliary types

public struct TaskTimeoutError: Error {}
