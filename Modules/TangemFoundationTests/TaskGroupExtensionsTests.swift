//
//  TaskGroupExtensionsTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemFoundation

@Suite("Tests for extensions from the TaskGroup+.swift file")
struct TaskGroupExtensionsTests {
    // MARK: - runTask (async overload)

    @Test("Code completes before timeout — returns result")
    func asyncRunTaskReturnsResult() async throws {
        let result: Int = try await TaskGroup.runTask(timeout: .seconds(1)) {
            try await Task.sleep(for: .milliseconds(50))
            return 42
        }

        #expect(result == 42)
    }

    @Test("Code exceeds timeout — throws TimeoutError")
    func asyncRunTaskThrowsOnTimeout() async {
        await #expect(throws: TimeoutError.self) {
            try await TaskGroup<Int>.runTask(timeout: .milliseconds(50)) {
                try await Task.sleep(for: .seconds(10))
                return 0
            }
        }
    }

    @Test("Code throws before timeout — error is propagated")
    func asyncRunTaskPropagatesCodeError() async {
        await #expect(throws: RunTaskTestError.self) {
            try await TaskGroup<Int>.runTask(timeout: .seconds(1)) {
                throw RunTaskTestError()
            }
        }
    }

    @Test("Caller cancellation is propagated")
    func asyncRunTaskPropagatesCancellation() async {
        let task = Task<Int, Error> {
            try await TaskGroup.runTask(timeout: .seconds(10)) {
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

    // MARK: - runTask (fire-and-forget overload)

    @Test("Fire-and-forget overload — code completes before timeout")
    func fireAndForgetRunTaskReturnsResult() async throws {
        let task: Task<Int, Error> = TaskGroup.runTask(timeout: .seconds(1)) {
            try await Task.sleep(for: .milliseconds(50))
            return 7
        }

        let result = try await task.value
        #expect(result == 7)
    }

    @Test("Fire-and-forget overload — timeout fires and calls onTimeout")
    func fireAndForgetRunTaskCallsOnTimeout() async throws {
        let onTimeoutCalled = OSAllocatedUnfairLock(initialState: false)

        let task: Task<Int, Error> = TaskGroup.runTask(
            timeout: .milliseconds(50),
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
            Issue.record("Expected TimeoutError")
        } catch is TimeoutError {
            let wasCalled = onTimeoutCalled.withLock { $0 }
            #expect(wasCalled)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("Fire-and-forget overload — code error is propagated, onTimeout is not called")
    func fireAndForgetRunTaskPropagatesCodeError() async throws {
        let onTimeoutCalled = OSAllocatedUnfairLock(initialState: false)

        let task: Task<Int, Error> = TaskGroup.runTask(
            timeout: .seconds(1),
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

    // MARK: - executeKeepingOrder

    @Test(
        "Test `TaskGroup.executeKeepingOrder` helper method",
        arguments: [
            [3, 1, 2, 5, 4, 2, 1],
            [],
            [1, 2, 3, 4],
            [Int](repeating: Int.random(in: 0 ... 5), count: 100),
        ]
    )
    func testExecuteKeepingOrder(numbers: [Int]) async throws {
        let expectedResult = numbers.map(String.init)

        let givenResult = await TaskGroup.executeKeepingOrder(items: numbers, action: processItem)
        #expect(givenResult == expectedResult)
    }

    @Test(
        "Test `TaskGroup.tryExecuteKeepingOrder` helper method",
        arguments: [
            [3, 1, 2, 5, 4, 2, 1],
            [],
            [1, 2, 3, 4],
            [Int](repeating: Int.random(in: 0 ... 5), count: 100),
        ]
    )
    func testTryExecuteKeepingOrder(numbers: [Int]) async throws {
        let expectedResult = numbers.map(String.init)

        let givenResult = try await TaskGroup.tryExecuteKeepingOrder(items: numbers, action: tryProcessItem)
        #expect(givenResult == expectedResult)
    }

    private func processItem(_ item: Int) async -> String {
        return await Task.detached {
            try? await Task.sleep(for: .milliseconds(item * 100))
            return "\(item)"
        }.value
    }

    private func tryProcessItem(_ item: Int) async throws -> String {
        return try await Task.detached {
            try await Task.sleep(for: .milliseconds(item * 100))
            return "\(item)"
        }.value
    }
}

// MARK: - Test helpers

private extension TaskGroupExtensionsTests {
    struct RunTaskTestError: Error {}
}
