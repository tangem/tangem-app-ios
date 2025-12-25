//
//  SingleTaskProcessor.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

/// Runs at most one async task at a time and shares the in-flight result with all callers.
/// If a task is running, new `execute` calls await the same result. When it finishes, a new task can start.
/// Note: If the current task was cancelled, callers awaiting it will receive `CancellationError`.
/// - Generic parameter `Result`: The value returned by the task.
public actor SingleTaskProcessor<Result, Failure: Error> {
    private var currentTask: Task<Result, Failure>?

    public init() {}

    /// Cancel the current task (if any) and clear state.
    public func cancel() {
        currentTask?.cancel()
        currentTask = nil
    }
}

// MARK: - Non-throwable

public extension SingleTaskProcessor where Failure == Never {
    /// Execute the action, ensuring only one task runs at a time. Concurrent callers await the same result.
    func execute(action: @escaping @Sendable () async -> Result) async -> Result {
        if let task = currentTask {
            let currentResult = await task.value
            return currentResult
        }

        let task = Task {
            // Clear the reference after completion so future calls can start a new task
            defer { currentTask = nil }

            let result = await action()
            return result
        }

        currentTask = task
        return await task.value
    }
}

// MARK: - Throwable

public extension SingleTaskProcessor where Failure == Error {
    /// Execute the throwing action with single-flight behavior. Concurrent callers await the same result.
    func execute(action: @escaping @Sendable () async throws -> Result) async throws -> Result {
        if let task = currentTask {
            let currentResult = try await task.value
            return currentResult
        }

        let task = Task {
            // Clear the reference after completion so future calls can start a new task
            defer { currentTask = nil }

            let result = try await action()
            return result
        }

        currentTask = task
        return try await task.value
    }
}
