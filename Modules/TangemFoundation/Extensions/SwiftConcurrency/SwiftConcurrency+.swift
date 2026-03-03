//
//  SwiftConcurrency+.swift
//  TangemFoundation
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import class Combine.AnyCancellable

// MARK: - Helpers

@discardableResult
@MainActor
public func runOnMain<T>(_ code: () throws -> T) rethrows -> T {
    return try code()
}

public func runInTask<T>(
    isDetached: Bool = false,
    priority: TaskPriority? = nil,
    code: @escaping () async throws -> T
) async throws -> T {
    return try await isDetached ? Task.detached(priority: priority, operation: code).value : Task(priority: priority, operation: code).value
}

@discardableResult
public func runTask(
    isDetached: Bool = false,
    priority: TaskPriority? = nil,
    code: @escaping () -> Void
) -> Task<Void, Never> {
    return isDetached ? Task.detached(priority: priority, operation: code) : Task(priority: priority, operation: code)
}

@discardableResult
public func runTask(
    isDetached: Bool = false,
    priority: TaskPriority? = nil,
    code: @escaping () async -> Void
) -> Task<Void, Never> {
    return isDetached ? Task.detached(priority: priority, operation: code) : Task(priority: priority, operation: code)
}

@discardableResult
public func runTask(
    isDetached: Bool = false,
    priority: TaskPriority? = nil,
    code: @escaping () async throws -> Void
) -> Task<Void, Error> {
    return isDetached ? Task.detached(priority: priority, operation: code) : Task(priority: priority, operation: code)
}

@discardableResult
public func runTask<T: AnyObject>(
    in object: T,
    isDetached: Bool = false,
    priority: TaskPriority? = nil,
    code: @escaping (_ input: T) async -> Void
) -> Task<Void, Never> {
    let operation = { [weak object] in
        guard let object else { return }

        await code(object)
    }

    return isDetached ? Task.detached(priority: priority, operation: operation) : Task(priority: priority, operation: operation)
}

@discardableResult
public func runTask<T: AnyObject>(
    in object: T,
    isDetached: Bool = false,
    priority: TaskPriority? = nil,
    code: @escaping (_ input: T) async throws -> Void
) -> Task<Void, Error> {
    let operation = { [weak object] in
        guard let object else { return }

        try await code(object)
    }

    return isDetached ? Task.detached(priority: priority, operation: operation) : Task(priority: priority, operation: operation)
}

public func runTask<T>(
    withMinimumTime time: TimeInterval,
    code: @escaping () async throws -> T
) async throws -> Task<T, Error> {
    Task {
        async let update = code()
        async let minimumWaitingTime: () = Task.sleep(for: .seconds(time))

        let (result, _) = try await (update, minimumWaitingTime)

        return result
    }
}

/// Runs an async operation and, if it doesn't finish within `thresholdSeconds`, calls `onLongRunning` once.
@discardableResult
public func runWithDelayedLoading<T>(
    thresholdSeconds: TimeInterval = 0.3,
    onLongRunning: @escaping @MainActor () async -> Void,
    onCancel: @escaping () -> Void = {},
    operation: @escaping () async throws -> T
) -> Task<T, Error> {
    Task {
        // Start a delayed task that will call onLongRunning after the threshold unless cancelled.
        let loadingTask = Task {
            try await Task.sleep(for: .seconds(thresholdSeconds))
            try Task.checkCancellation()

            await onLongRunning()
        }

        return try await withTaskCancellationHandler {
            defer { loadingTask.cancel() }

            // Run the main operation
            let result = try await operation()
            try Task.checkCancellation()
            return result
        } onCancel: {
            loadingTask.cancel()
            onCancel()
        }
    }
}

// MARK: - Convenience extensions

public extension Task where Failure == Error {
    static func delayed(
        withDelay delaySeconds: TimeInterval,
        priority: TaskPriority? = nil,
        operation: @escaping @Sendable () async throws -> Success
    ) -> Task {
        Task(priority: priority) {
            if delaySeconds > 0 {
                try await Task<Never, Never>.sleep(for: .seconds(delaySeconds))
            }
            try Task<Never, Never>.checkCancellation()
            return try await operation()
        }
    }
}

public extension Task {
    func eraseToAnyCancellable() -> AnyCancellable {
        return AnyCancellable(cancel)
    }
}

public extension Actor {
    /// Based on https://medium.com/@noahlittle199/swifts-isolated-keyword-a-small-trick-to-simplify-code-in-actors-570ff692f8e2
    func performIsolated<T>(_ closure: (isolated Self) throws -> T) rethrows -> T {
        return try closure(self)
    }
}

// MARK: - Auxiliary types

public enum RunTaskError: Error {
    case timeout
}
