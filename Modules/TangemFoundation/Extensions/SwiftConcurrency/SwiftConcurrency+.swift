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

@discardableResult
public func runTask<T>(
    withTimeout timeout: TimeInterval,
    code: @escaping () async -> T,
    onTimeout: @escaping () -> Void = {}
) -> Task<T, Error> {
    Task.detached {
        do {
            return try await runTask(withTimeout: timeout, code: code)
        } catch let taskError as RunTaskError {
            switch taskError {
            case .timeout:
                onTimeout()
            }

            throw taskError
        } catch {
            throw error
        }
    }
}

public func runTask<T>(
    withTimeout timeout: TimeInterval,
    code: @escaping () async throws -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await code()
        }

        group.addTask {
            try await Task.sleepCancellable(forSeconds: timeout)

            try Task.checkCancellation()
            throw RunTaskError.timeout
        }

        // We can safely force-unwrap, because `group.next()` can return nil only when tasks weren't added to the group
        // Group will receive the first finished result, even if group schedules waiting for the next result after the first
        // task or all tasks execution finished.
        let result: T = try await group.next()!
        group.cancelAll()

        return result
    }
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

// MARK: - Private implementation

private extension Task where Success == Never, Failure == Never {
    static var defaultCancellationCheckInterval: TimeInterval { 0.1 }

    /// Like `Task.sleep` but with cancellation support.
    ///
    /// - Parameter seconds: Sleep this number of seconds. The actual time the sleep ends can be later.
    /// - Parameter cancellationCheckInterval: The interval in seconds between cancellation checks.
    static func sleepCancellable(forSeconds seconds: TimeInterval, cancellationCheckInterval: TimeInterval = defaultCancellationCheckInterval) async throws {
        try await sleepCancellable(until: Date().addingTimeInterval(seconds), cancellationCheckInterval: cancellationCheckInterval)
    }

    /// Like `Task.sleep` but with cancellation support.
    ///
    /// - Parameter deadline: Sleep at least until this time. The actual time the sleep ends can be later.
    /// - Parameter cancellationCheckInterval: The interval in seconds between cancellation checks.
    static func sleepCancellable(until deadline: Date, cancellationCheckInterval: TimeInterval = defaultCancellationCheckInterval) async throws {
        let cancellationCheckIntervalUint64 = UInt64(cancellationCheckInterval) * NSEC_PER_SEC
        while Date() < deadline {
            if Task.isCancelled {
                break
            }
            // Sleep for a while between cancellation checks.
            try await Task.sleep(nanoseconds: cancellationCheckIntervalUint64)
        }
    }
}
