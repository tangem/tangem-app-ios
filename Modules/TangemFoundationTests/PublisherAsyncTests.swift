//
//  PublisherAsyncTests.swift
//  TangemFoundationTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

@preconcurrency import Combine
import Foundation
import Testing
@testable import TangemFoundation

@Suite("Publisher.async() tests")
struct PublisherAsyncTests {
    // MARK: - Normal paths

    @Test("Returns value from a synchronous publisher (Just)")
    func returnsValueFromSynchronousPublisher() async throws {
        let value = try await Just(42).async()
        #expect(value == 42)
    }

    @Test("Returns value from an asynchronous publisher (PassthroughSubject)")
    func returnsValueFromAsynchronousPublisher() async throws {
        nonisolated(unsafe) let subject = PassthroughSubject<Int, Never>()

        Task {
            try await Task.sleep(for: .milliseconds(50))
            subject.send(99)
        }

        let value = try await subject.async()
        #expect(value == 99)
    }

    @Test("Returns value from a delayed Future")
    func returnsValueFromDelayedFuture() async throws {
        let future = Future<Int, Never> { promise in
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.05) {
                promise(.success(7))
            }
        }

        let value = try await future.async()
        #expect(value == 7)
    }

    @Test("Throws when publisher completes without emitting a value")
    func throwsWhenPublisherCompletesWithoutValue() async {
        await #expect(throws: AsyncError.self) {
            try await Empty<Int, Never>(completeImmediately: true).async()
        }
    }

    @Test("Throws synchronous upstream error")
    func throwsSynchronousUpstreamError() async {
        await #expect(throws: TestError.self) {
            try await Fail<Int, TestError>(error: TestError()).async()
        }
    }

    @Test("Throws asynchronous upstream error")
    func throwsAsynchronousUpstreamError() async {
        nonisolated(unsafe) let subject = PassthroughSubject<Int, TestError>()

        Task {
            try await Task.sleep(for: .milliseconds(50))
            subject.send(completion: .failure(TestError()))
        }

        await #expect(throws: TestError.self) {
            try await subject.async()
        }
    }

    @Test("Returns only the first value from multiple emissions")
    func returnsOnlyFirstValueFromMultipleEmissions() async throws {
        nonisolated(unsafe) let subject = PassthroughSubject<Int, Never>()

        Task {
            try await Task.sleep(for: .milliseconds(50))
            subject.send(1)
            subject.send(2)
            subject.send(3)
        }

        let value = try await subject.async()
        #expect(value == 1)
    }

    @Test("Returns first from a multi-element synchronous publisher")
    func returnsFirstFromMultiElementSynchronousPublisher() async throws {
        let value = try await [10, 20, 30].publisher.async()
        #expect(value == 10)
    }

    // MARK: - Cancellation paths

    @Test("Throws CancellationError when task is already cancelled")
    func throwsCancellationWhenTaskAlreadyCancelled() async {
        await withTaskGroup(of: Void.self) { group in
            group.cancelAll()
            group.addTask {
                await #expect(throws: CancellationError.self) {
                    try await Just(42).async()
                }
            }
        }
    }

    @Test("Throws CancellationError when cancelled before emission")
    func throwsCancellationWhenCancelledBeforeEmission() async {
        nonisolated(unsafe) let subject = PassthroughSubject<Int, Never>()

        let task = Task {
            try await subject.async()
        }

        try? await Task.sleep(for: .milliseconds(50))
        task.cancel()

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
    }

    @Test("Returns value when cancellation arrives after emission")
    func returnsValueWhenCancellationArrivesLate() async throws {
        nonisolated(unsafe) let subject = PassthroughSubject<Int, Never>()

        let task = Task {
            try await subject.async()
        }

        try? await Task.sleep(for: .milliseconds(50))
        subject.send(42)

        try? await Task.sleep(for: .milliseconds(50))
        task.cancel()

        let value = try await task.value
        #expect(value == 42)
    }

    @Test("Cancellation breaks out of a hanging publisher promptly")
    func cancellationBreaksOutOfHangingPublisher() async throws {
        nonisolated(unsafe) let subject = PassthroughSubject<Int, Never>()
        let maxAcceptableWallTime: Duration = .seconds(1)

        let clock = ContinuousClock()
        let elapsed = await clock.measure {
            let task = Task {
                try await subject.async()
            }

            try? await Task.sleep(for: .milliseconds(50))
            task.cancel()

            await #expect(throws: CancellationError.self) {
                try await task.value
            }
        }

        #expect(elapsed < maxAcceptableWallTime)
    }

    // MARK: - Race conditions

    @Test("Concurrent emission and cancellation race produces exactly one outcome")
    func concurrentEmissionAndCancellationRace() async {
        let iterations = 500

        for _ in 0 ..< iterations {
            nonisolated(unsafe) let subject = PassthroughSubject<Int, Never>()

            let task = Task {
                try await subject.async()
            }

            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    subject.send(1)
                }
                group.addTask {
                    task.cancel()
                }
            }

            do {
                let value = try await task.value
                #expect(value == 1)
            } catch is CancellationError {
                // Also acceptable
            } catch {
                Issue.record("Unexpected error: \(error)")
            }
        }
    }
}

// MARK: - Test helpers

private extension PublisherAsyncTests {
    struct TestError: Error {}
}
