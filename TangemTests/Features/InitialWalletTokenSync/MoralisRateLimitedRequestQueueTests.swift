//
//  MoralisRateLimitedRequestQueueTests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

// MARK: - MoralisRateLimitedRequestQueue Tests

struct MoralisRateLimitedRequestQueueTests {
    @Test
    func allowsConcurrentUpToLimit() async throws {
        let queue = MoralisRateLimitedRequestQueue(maxConcurrentRequests: 3)
        let started = ManagedAtomic<Int>(0)

        try await withThrowingTaskGroup(of: Void.self) { group in
            for _ in 0 ..< 3 {
                group.addTask {
                    try await queue.execute {
                        started.increment()
                        try await Task.sleep(for: .milliseconds(50))
                    }
                }
            }

            try await Task.sleep(for: .milliseconds(20))
            #expect(started.value >= 3)

            try await group.waitForAll()
        }
    }

    @Test
    func blocksWhenAtLimit() async throws {
        let queue = MoralisRateLimitedRequestQueue(maxConcurrentRequests: 2)
        let started = ManagedAtomic<Int>(0)

        try await withThrowingTaskGroup(of: Void.self) { group in
            for _ in 0 ..< 2 {
                group.addTask {
                    try await queue.execute {
                        started.increment()
                        try await Task.sleep(for: .milliseconds(100))
                    }
                }
            }

            try await Task.sleep(for: .milliseconds(20))

            group.addTask {
                try await queue.execute {
                    started.increment()
                }
            }

            try await Task.sleep(for: .milliseconds(20))
            #expect(started.value == 2)

            try await group.waitForAll()
            #expect(started.value == 3)
        }
    }

    @Test
    func propagatesErrors() async throws {
        let queue = MoralisRateLimitedRequestQueue(maxConcurrentRequests: 3)

        await #expect(throws: TestError.self) {
            try await queue.execute { throw TestError() }
        }
    }

    @Test
    func releasesSlotOnFailure() async throws {
        let queue = MoralisRateLimitedRequestQueue(maxConcurrentRequests: 1)

        try? await queue.execute { throw TestError() }

        let result = try await queue.execute { 42 }
        #expect(result == 42)
    }
}

// MARK: - Helpers

private struct TestError: Error {}

/// Minimal lock-free atomic counter for test assertions across concurrent tasks.
private final class ManagedAtomic<Value: AdditiveArithmetic & Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var _value: Value

    var value: Value {
        lock.withLock { _value }
    }

    init(_ initial: Value) {
        _value = initial
    }

    func increment() where Value == Int {
        lock.withLock { _value += 1 }
    }
}
