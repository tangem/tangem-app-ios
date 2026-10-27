//
//  PublisherAsyncTests.swift
//  TangemFoundationTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@preconcurrency import Combine
@testable import TangemFoundation

@Suite("Publisher.async() tests", .timeLimit(.minutes(1)))
struct PublisherAsyncTests {
    // MARK: - Normal paths

    @Test("Returns value from a synchronous publisher (Just)")
    func returnsValueFromSynchronousPublisher() async throws {
        let value = try await Just(42).async()
        #expect(value == 42)
    }

    @Test("Returns value from an asynchronous publisher (PassthroughSubject)")
    func returnsValueFromAsynchronousPublisher() async throws {
        let queue = DispatchQueue(label: Constants.queueLabel)
        let requested = TestSignal<Void>()
        let subject = PassthroughSubject<Int, Never>()

        let task = Task {
            try await subject
                .handleEvents(receiveRequest: { _ in
                    requested.fire()
                })
                .subscribe(on: queue)
                .async()
        }

        await requested.wait()
        queue.async {
            subject.send(99)
        }

        let value = try await task.value
        #expect(value == 99)
    }

    @Test("Returns value from a Future fulfilled on another queue")
    func returnsValueFromFutureFulfilledOnAnotherQueue() async throws {
        let queue = DispatchQueue(label: Constants.queueLabel)

        let value = try await Deferred {
            Future<Int, Never> { promise in
                // Safe: `Future` locks its promise internally, and it's called once, on the serial `queue` the future is subscribed on
                nonisolated(unsafe) let promise = promise
                queue.async {
                    promise(.success(7))
                }
            }
        }
        .subscribe(on: queue)
        .async()

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
        let queue = DispatchQueue(label: Constants.queueLabel)
        let requested = TestSignal<Void>()
        let subject = PassthroughSubject<Int, TestError>()

        let task = Task {
            try await subject
                .handleEvents(receiveRequest: { _ in
                    requested.fire()
                })
                .subscribe(on: queue)
                .async()
        }

        await requested.wait()
        queue.async {
            subject.send(completion: .failure(TestError()))
        }

        await #expect(throws: TestError.self) {
            try await task.value
        }
    }

    @Test("Returns only the first value from multiple emissions")
    func returnsOnlyFirstValueFromMultipleEmissions() async throws {
        let queue = DispatchQueue(label: Constants.queueLabel)
        let requested = TestSignal<Void>()
        let subject = PassthroughSubject<Int, Never>()

        let task = Task {
            try await subject
                .handleEvents(receiveRequest: { _ in
                    requested.fire()
                })
                .subscribe(on: queue)
                .async()
        }

        await requested.wait()
        queue.async {
            subject.send(1)
            subject.send(2)
            subject.send(3)
        }

        let value = try await task.value
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
        let requested = TestSignal<Void>()

        let task = Task {
            try await PassthroughSubject<Int, Never>()
                .handleEvents(receiveRequest: { _ in
                    requested.fire()
                })
                .async()
        }

        await requested.wait()
        task.cancel()

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
    }

    @Test("Returns value when cancellation arrives after emission")
    func returnsValueWhenCancellationArrivesLate() async throws {
        let queue = DispatchQueue(label: Constants.queueLabel)
        let requested = TestSignal<Void>()
        let delivered = TestSignal<Void>()
        let subject = PassthroughSubject<Int, Never>()

        let task = Task {
            try await subject
                .handleEvents(receiveRequest: { _ in
                    requested.fire()
                })
                .subscribe(on: queue)
                .async()
        }

        await requested.wait()
        queue.async {
            subject.send(42)
            delivered.fire()
        }

        await delivered.wait()
        task.cancel()

        let value = try await task.value
        #expect(value == 42)
    }

    @Test("Cancellation breaks out of a publisher that never emits nor completes")
    func cancellationBreaksOutOfHangingPublisher() async {
        let requested = TestSignal<Void>()

        let task = Task {
            try await Empty<Int, Never>(completeImmediately: false)
                .handleEvents(receiveRequest: { _ in
                    requested.fire()
                })
                .async()
        }

        await requested.wait()
        task.cancel()

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
    }

    // MARK: - Race conditions

    @Test("Concurrent emission and cancellation race produces exactly one outcome using GCD")
    func concurrentEmissionAndCancellationRaceUsingGCD() async {
        for _ in 0 ..< 500 {
            let subject = PassthroughSubject<Int, Never>()

            let task = Task {
                try await subject.async()
            }

            // The order of these two calls is non-deterministic
            DispatchQueue.global().async { task.cancel() }
            DispatchQueue.global().async { subject.send(42) }

            // Invariant: must resolve to either the value or CancellationError
            do {
                let value = try await task.value
                #expect(value == 42)
            } catch {
                #expect(error is CancellationError)
            }
        }
    }

    @Test("Concurrent emission and cancellation race produces exactly one outcome using Swift Concurrency")
    func concurrentEmissionAndCancellationRaceUsingConcurrency() async {
        for _ in 0 ..< 500 {
            let subject = PassthroughSubject<Int, Never>()

            let task = Task {
                try await subject.async()
            }

            // The order of these two calls is non-deterministic
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    subject.send(42)
                }
                group.addTask {
                    task.cancel()
                }
            }

            // Invariant: must resolve to either the value or CancellationError
            do {
                let value = try await task.value
                #expect(value == 42)
            } catch {
                #expect(error is CancellationError)
            }
        }
    }
}

// MARK: - Test helpers

private extension PublisherAsyncTests {
    struct TestError: Error {}
}

// MARK: - Constants

private enum Constants {
    static let queueLabel = "com.tangem.PublisherAsyncTests"
}
