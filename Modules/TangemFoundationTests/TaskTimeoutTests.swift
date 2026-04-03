//
//  TaskTimeoutTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemFoundation

@Suite("Tests for Task.run(withTimeout:) from the Task+Timeout.swift file")
struct TaskTimeoutTests {
    // MARK: - run(withTimeout:) (async overload)

    @Test("Code completes before timeout — returns result")
    func asyncRunTaskReturnsResult() async throws {
        let result: Int = try await Task.run(withTimeout: .seconds(1)) {
            try await Task.sleep(for: .milliseconds(50))
            return 42
        }

        #expect(result == 42)
    }

    @Test("Code exceeds timeout — throws TaskTimeoutError")
    func asyncRunTaskThrowsOnTimeout() async {
        await #expect(throws: TaskTimeoutError.self) {
            try await Task<Int, Error>.run(withTimeout: .milliseconds(50)) {
                try await Task.sleep(for: .seconds(10))
                return 0
            }
        }
    }

    /// This unit test is needed to guard against the following behavior of `Swift.TaskGroup`:
    ///
    /// Swift Concurrency task group does not return early after the single `await taskGroup.nextResult()` call.
    /// The task group will always wait for all child tasks to finish before it ends.
    /// See https://forums.swift.org/t/running-an-async-task-with-a-timeout/49733/15 and other posts in that thread for more details.
    @Test("Timeout returns promptly without waiting for slow code to finish")
    func asyncRunTaskDoesNotWaitForSlowCode() async throws {
        let timeout: Duration = .milliseconds(100)
        let slowCodeDuration: Duration = .seconds(5)
        // Max acceptable wall time can't be equal to the timeout time, because adding a new task (a 'timeout' task in this case)
        // to the Swift Concurrency thread pool DOES NOT guarantee that the task will start executing immediately.
        // So we accept some drift here, but it should be far less than the slow code duration.
        let maxAcceptableWallTime: Duration = .seconds(1)

        let clock = ContinuousClock()
        let elapsed = await clock.measure {
            await #expect(throws: TaskTimeoutError.self) {
                try await Task<Int, Error>.run(withTimeout: timeout, clock: clock) {
                    try await Task.sleep(for: slowCodeDuration, clock: clock)
                    return 0
                }
            }
        }

        #expect(elapsed < maxAcceptableWallTime)
    }

    /// This unit test is needed to guard against the following behavior of `Swift.TaskGroup`:
    ///
    /// Swift Concurrency task group does not return early after the single `await taskGroup.nextResult()` call.
    /// The task group will always wait for all child tasks to finish before it ends.
    /// See https://forums.swift.org/t/running-an-async-task-with-a-timeout/49733/15 and other posts in that thread for more details.
    @Test("Fire-and-forget overload: timeout returns promptly without waiting for slow code to finish")
    func fireAndForgetRunTaskDoesNotWaitForSlowCode() async throws {
        let timeout: Duration = .milliseconds(100)
        let slowCodeDuration: Duration = .seconds(5)
        // Max acceptable wall time can't be equal to the timeout time, because adding a new task (a 'timeout' task in this case)
        // to the Swift Concurrency thread pool DOES NOT guarantee that the task will start executing immediately.
        // So we accept some drift here, but it should be far less than the slow code duration.
        let maxAcceptableWallTime: Duration = .seconds(1)

        let clock = ContinuousClock()
        let elapsed = await clock.measure {
            await #expect(throws: TaskTimeoutError.self) {
                let task: Task<Int, Error> = Task.run(withTimeout: timeout, clock: clock) {
                    try await Task.sleep(for: slowCodeDuration, clock: clock)
                    return 0
                }
                return try await task.value
            }
        }

        #expect(elapsed < maxAcceptableWallTime)
    }

    @Test("Code throws before timeout — error is propagated")
    func asyncRunTaskPropagatesCodeError() async {
        await #expect(throws: RunTaskTestError.self) {
            try await Task<Int, Error>.run(withTimeout: .seconds(1)) {
                throw RunTaskTestError()
            }
        }
    }

    @Test("Caller cancellation is propagated")
    func asyncRunTaskPropagatesCancellation() async {
        let task = Task<Int, Error> {
            try await Task.run(withTimeout: .seconds(10)) {
                try await Task.sleep(for: .seconds(10))
                return 0
            }
        }

        // Give the inner work time to start
        try? await Task.sleep(for: .milliseconds(50))
        task.cancel()

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
    }

    @Test(
        "Code executed by runTask(withTimeout:) inherits Task.Priority",
        arguments: [
            TaskPriority.background,
            TaskPriority.low,
            TaskPriority.medium,
            TaskPriority.high,
            TaskPriority.userInitiated
        ]
    )
    func runTaskWithTimeoutInheritsParentPriority(_ taskPriority: TaskPriority) async throws {
        let anyDuration = Duration.seconds(42)

        let task = Task(priority: taskPriority) {
            let innerTask: Task<Void, any Error> = Task.run(withTimeout: anyDuration) {
                #expect(Task.currentPriority == taskPriority)
            }

            try await innerTask.value
        }

        try await task.value
    }

    // MARK: - run(withTimeout:) (fire-and-forget overload)

    @Test("Fire-and-forget overload — code completes before timeout")
    func fireAndForgetRunTaskReturnsResult() async throws {
        let task: Task<Int, Error> = Task.run(withTimeout: .seconds(1)) {
            try await Task.sleep(for: .milliseconds(50))
            return 7
        }

        let result = try await task.value
        #expect(result == 7)
    }

    @Test("Fire-and-forget overload — timeout fires and calls onTimeout")
    func fireAndForgetRunTaskCallsOnTimeout() async throws {
        let onTimeoutCalled = OSAllocatedUnfairLock(initialState: false)

        let task: Task<Int, Error> = Task.run(
            withTimeout: .milliseconds(50),
            code: {
                try await Task.sleep(for: .seconds(10))
                return 0
            },
            onTimeout: {
                onTimeoutCalled.withLock { $0 = true }
            }
        )

        do {
            _ = try await task.value
            Issue.record("Expected TaskTimeoutError")
        } catch is TaskTimeoutError {
            let wasCalled = onTimeoutCalled.withLock { $0 }
            #expect(wasCalled)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("Fire-and-forget overload — code error is propagated, onTimeout is not called")
    func fireAndForgetRunTaskPropagatesCodeError() async throws {
        let onTimeoutCalled = OSAllocatedUnfairLock(initialState: false)

        let task: Task<Int, Error> = Task.run(
            withTimeout: .seconds(1),
            code: {
                throw RunTaskTestError()
            },
            onTimeout: {
                onTimeoutCalled.withLock { $0 = true }
            }
        )

        do {
            _ = try await task.value
            Issue.record("Expected RunTaskTestError")
        } catch is RunTaskTestError {
            let wasCalled = onTimeoutCalled.withLock { $0 }
            #expect(!wasCalled)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}

// MARK: - Test helpers

private extension TaskTimeoutTests {
    struct RunTaskTestError: Error {}
}
