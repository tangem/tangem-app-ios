//
//  TaskGroup+.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - Execute with timeout

public extension TaskGroup {
    @discardableResult
    static func runTask<C>(
        timeout: C.Instant.Duration,
        tolerance: C.Instant.Duration? = nil,
        clock: C = .continuous,
        code: @escaping @Sendable () async throws -> ChildTaskResult,
        onTimeout: @escaping () -> Void = {}
    ) -> Task<ChildTaskResult, Error> where ChildTaskResult: Sendable, C: Clock {
        Task.detached {
            do {
                return try await runTask(timeout: timeout, tolerance: tolerance, clock: clock, code: code)
            } catch let error as TimeoutError {
                onTimeout()
                throw error
            } catch {
                throw error
            }
        }
    }

    static func runTask<C>(
        timeout: C.Instant.Duration,
        tolerance: C.Instant.Duration? = nil,
        clock: C = .continuous,
        code: @escaping @Sendable () async throws -> ChildTaskResult
    ) async throws -> ChildTaskResult where ChildTaskResult: Sendable, C: Clock {
        let cancellableWrapper = ThreadSafeCancellableWrapper()

        // This `withTaskCancellationHandler` scope is absolutely necessary to propagate cancellation from the parent task.
        return try await withTaskCancellationHandler {
            // This `withCheckedThrowingContinuation` scope is absolutely necessary because Swift Concurrency task group
            // does not return early after the single `await taskGroup.nextResult()` call.
            // The task group will always wait for all child tasks to finish before it ends therefore we use Continuation API
            // to resume the parent task as soon as one of the child tasks finishes and then cancel the other one.
            // See https://forums.swift.org/t/running-an-async-task-with-a-timeout/49733/15 and other posts in that thread for more details.
            return try await withCheckedThrowingContinuation { continuation in
                let continuationWrapper = ResumableOnceCheckedContinuationWrapper(continuation)

                // This check is necessary in case this code runs after the task was
                // cancelled. In which case we want to bail right away.
                guard !Task.isCancelled else {
                    continuationWrapper.resumeIfNeeded(throwing: CancellationError())
                    return
                }

                Task.detached {
                    try await withThrowingTaskGroup(of: Void.self) { taskGroup in
                        defer { taskGroup.cancelAll() }

                        taskGroup.addTask {
                            do {
                                let result = try await code()
                                await continuationWrapper.resumeIfNeeded(returning: result)
                            } catch {
                                await continuationWrapper.resumeIfNeeded(throwing: error)
                            }
                        }

                        taskGroup.addTask {
                            do {
                                try await Task.sleep(for: timeout, tolerance: tolerance, clock: clock)
                                try Task.checkCancellation()
                                await continuationWrapper.resumeIfNeeded(throwing: TimeoutError())
                            } catch {
                                await continuationWrapper.resumeIfNeeded(throwing: error)
                            }
                        }

                        await taskGroup.nextResult()
                    }
                }.eraseToAnyCancellable().store(in: cancellableWrapper)
            }
        } onCancel: {
            cancellableWrapper.cancel()
        }
    }
}

// MARK: - Ordered concurrent execution

public extension TaskGroup {
    /// Executes an async action for each item concurrently and returns results in the original order.
    /// - Parameters:
    ///   - items: The items to process.
    ///   - action: The async work to perform for each item.
    /// - Returns: An array of results ordered to match the input items.
    static func executeKeepingOrder<Item>(items: [Item], action: @escaping (Item) async -> ChildTaskResult) async -> [ChildTaskResult] {
        let count = items.count

        return await withTaskGroup(of: (Int, ChildTaskResult).self) { group in
            for index in 0 ..< count {
                let item = items[index]
                group.addTask {
                    let processedItem = await action(item)
                    return (index, processedItem)
                }
            }

            var result = [ChildTaskResult?](repeating: nil, count: count)

            for await (index, processedItem) in group {
                result[index] = processedItem
            }

            return result.compactMap(\.self)
        }
    }

    /// Executes an async throwing action for each item concurrently and returns results in the original order.
    /// - Parameters:
    ///   - items: The items to process.
    ///   - action: The async throwing work to perform for each item.
    /// - Returns: An array of results ordered to match the input items.
    /// - Throws: Rethrows any error thrown by `action`.
    static func tryExecuteKeepingOrder<Item>(items: [Item], action: @escaping (Item) async throws -> ChildTaskResult) async rethrows -> [ChildTaskResult] {
        let count = items.count

        return try await withThrowingTaskGroup(of: (Int, ChildTaskResult).self) { group in
            for index in 0 ..< count {
                let item = items[index]
                group.addTask {
                    let processedItem = try await action(item)
                    return (index, processedItem)
                }
            }

            var result = [ChildTaskResult?](repeating: nil, count: count)

            for try await (index, processedItem) in group {
                result[index] = processedItem
            }

            return result.compactMap(\.self)
        }
    }
}

// MARK: - Void convenience overloads.

public extension TaskGroup<Void> {
    /// Executes an async action for each item concurrently.
    /// - Parameters:
    ///   - items: The items to process.
    ///   - action: The async work to perform for each item.
    static func execute<Item>(items: [Item], action: @escaping (Item) async -> Void) async {
        _ = await executeKeepingOrder(items: items, action: action)
    }

    /// Executes an async throwing action for each item concurrently.
    /// - Parameters:
    ///   - items: The items to process.
    ///   - action: The async throwing work to perform for each item.
    /// - Throws: Rethrows any error thrown by `action`.
    static func tryExecute<Item>(items: [Item], action: @escaping (Item) async throws -> Void) async throws {
        _ = try await tryExecuteKeepingOrder(items: items, action: action)
    }
}

// MARK: - Auxiliary types

public struct TimeoutError: Error {}
