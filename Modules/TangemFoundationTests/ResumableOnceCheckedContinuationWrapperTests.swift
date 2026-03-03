//
//  ResumableOnceCheckedContinuationWrapperTests.swift
//  TangemFoundationTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemFoundation

@Suite("ResumableOnceCheckedContinuationWrapper tests")
struct ResumableOnceCheckedContinuationWrapperTests {
    @Test("Resumes continuation with a value exactly once")
    func resumesWithValueOnce() async throws {
        let result: Int = try await withCheckedThrowingContinuation { continuation in
            let wrapper = ResumableOnceCheckedContinuationWrapper(continuation)
            wrapper.resumeIfNeeded(returning: 42)
        }

        #expect(result == 42)
    }

    @Test("Resumes continuation with an error exactly once")
    func resumesWithErrorOnce() async {
        await #expect(throws: TestError()) {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Int, Error>) in
                let wrapper = ResumableOnceCheckedContinuationWrapper(continuation)
                wrapper.resumeIfNeeded(throwing: TestError())
            }
        }
    }

    @Test("Second resume(returning:) after resume(returning:) is a no-op")
    func duplicateReturningIsNoOp() async throws {
        let result: Int = try await withCheckedThrowingContinuation { continuation in
            let wrapper = ResumableOnceCheckedContinuationWrapper(continuation)
            wrapper.resumeIfNeeded(returning: 1)
            wrapper.resumeIfNeeded(returning: 2)
        }

        #expect(result == 1)
    }

    @Test("resume(throwing:) after resume(returning:) is a no-op")
    func throwingAfterReturningIsNoOp() async throws {
        let result: Int = try await withCheckedThrowingContinuation { continuation in
            let wrapper = ResumableOnceCheckedContinuationWrapper(continuation)
            wrapper.resumeIfNeeded(returning: 99)
            wrapper.resumeIfNeeded(throwing: TestError())
        }

        #expect(result == 99)
    }

    @Test("resume(returning:) after resume(throwing:) is a no-op")
    func returningAfterThrowingIsNoOp() async {
        await #expect(throws: TestError()) {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Int, Error>) in
                let wrapper = ResumableOnceCheckedContinuationWrapper(continuation)
                wrapper.resumeIfNeeded(throwing: TestError())
                wrapper.resumeIfNeeded(returning: 42)
            }
        }
    }

    @Test("Concurrent resume(returning:) calls produce exactly one result")
    func concurrentReturningProducesOneResult() async throws {
        let iterations = 100

        for _ in 0 ..< iterations {
            let result: Int = try await withCheckedThrowingContinuation { continuation in
                let wrapper = ResumableOnceCheckedContinuationWrapper(continuation)

                for i in 0 ..< 10 {
                    DispatchQueue.global().async {
                        wrapper.resumeIfNeeded(returning: i)
                    }
                }
            }

            #expect((0 ..< 10).contains(result))
        }
    }

    @Test("Concurrent mixed resume calls produce exactly one resumption")
    func concurrentMixedResumesProduceOneResumption() async throws {
        let iterations = 100

        for _ in 0 ..< iterations {
            do {
                let result: Int = try await withCheckedThrowingContinuation { continuation in
                    let wrapper = ResumableOnceCheckedContinuationWrapper(continuation)

                    for i in 0 ..< 10 {
                        DispatchQueue.global().async {
                            if i.isMultiple(of: 2) {
                                wrapper.resumeIfNeeded(returning: i)
                            } else {
                                wrapper.resumeIfNeeded(throwing: TestError())
                            }
                        }
                    }
                }

                // If we got a value, it must be one of the even indices
                #expect(result.isMultiple(of: 2))
            } catch {
                #expect(error is TestError)
            }
        }
    }
}

// MARK: - Test helpers

private extension ResumableOnceCheckedContinuationWrapperTests {
    struct TestError: Error {}
}
