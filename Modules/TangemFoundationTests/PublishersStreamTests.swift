//
//  PublishersStreamTests.swift
//  TangemFoundationTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import Combine
@testable import TangemFoundation

@Suite("Publishers.stream() tests", .timeLimit(.minutes(1)))
struct PublishersStreamTests {
    // MARK: - Delivery

    @Test("An element yielded before the subscriber is attached is still delivered")
    func deliversElementYieldedBeforeTheSubscriberIsAttached() async {
        let (stream, continuation) = AsyncStream<Int>.makeStream()
        continuation.yield(42) // Yield an element before the subscriber is attached
        let publisher = Publishers.stream { stream }

        let received = await collect(from: publisher) {
            continuation.finish()
        }

        #expect(received == [42])
    }

    @Test("A stream that yields nothing completes without delivering a single element")
    func deliversNothingWhenTheStreamYieldsNothing() async {
        let (stream, continuation) = AsyncStream<Int>.makeStream()
        let publisher = Publishers.stream { stream }

        let received = await collect(from: publisher) {
            continuation.finish()
        }

        #expect(received.isEmpty)
    }

    @Test("Elements yielded after the subscription are delivered in order")
    func deliversElementsYieldedAfterTheSubscription() async {
        let (stream, continuation) = AsyncStream<Int>.makeStream()
        let publisher = Publishers.stream { stream }

        let received = await collect(from: publisher) {
            continuation.yield(1)
            continuation.yield(2)
            continuation.yield(3)
            continuation.finish()
        }

        #expect(received == [1, 2, 3])
    }

    @Test("A `nil` yielded by a stream of optionals is delivered like any other element")
    func deliversNilYieldedByAStreamOfOptionals() async {
        let (stream, continuation) = AsyncStream<Int?>.makeStream()
        let publisher = Publishers.stream { stream }

        let received = await collect(from: publisher) {
            continuation.yield(1)
            continuation.yield(nil)
            continuation.yield(3)
            continuation.finish()
        }

        #expect(received == [1, nil, 3])
    }

    // MARK: - Lifetime

    @Test("Cancelling the subscription cancels the iteration and therefore terminates the stream")
    func cancellingTheSubscriptionTerminatesTheStream() async throws {
        try await withCheckedThrowingContinuation { continuation in
            let publisher = Publishers.stream {
                AsyncStream<Int> { streamContinuation in
                    streamContinuation.onTermination = { reason in
                        switch reason {
                        case .cancelled:
                            continuation.resume()
                        case .finished:
                            continuation.resume(throwing: "Stream finished instead of being cancelled")
                        @unknown default:
                            continuation.resume(throwing: "Stream terminated for an unknown reason")
                        }
                    }
                }
            }

            publisher
                .sink()
                .cancel()
        }
    }

    @Test("Every subscription iterates a stream of its own instead of splitting a shared one")
    func everySubscriptionIteratesItsOwnStream() async {
        let (firstStream, firstContinuation) = AsyncStream<Int>.makeStream()
        let (secondStream, secondContinuation) = AsyncStream<Int>.makeStream()
        let pendingStreams = OSAllocatedUnfairLock(initialState: [firstStream, secondStream])
        let publisher = Publishers.stream { pendingStreams { $0.removeFirst() } }

        let firstReceived = await collect(from: publisher) {
            firstContinuation.yield(1)
            firstContinuation.yield(2)
            firstContinuation.finish()
        }

        let secondReceived = await collect(from: publisher) {
            secondContinuation.yield(3)
            secondContinuation.finish()
        }

        #expect(firstReceived == [1, 2])
        #expect(secondReceived == [3])
        #expect(pendingStreams { $0.isEmpty })
    }
}

// MARK: - Helpers

private extension PublishersStreamTests {
    /// - Note: Collecting through a Combine subscriber to avoid back-pressure and demand management from `AsyncPublisher`,
    /// which can interfere with the test's expectations.
    func collect<Element: Sendable>(
        from publisher: some Publisher<Element, Never>,
        emit: @escaping @Sendable () -> Void
    ) async -> [Element] {
        let received = OSAllocatedUnfairLock(initialState: [Element]())

        return await withCheckedContinuation { continuation in
            var cancellable: AnyCancellable?

            cancellable = publisher.sink(
                receiveCompletion: { _ in
                    continuation.resume(returning: received { $0 })
                    withExtendedLifetime(cancellable) {}
                },
                receiveValue: { element in
                    received { $0.append(element) }
                }
            )

            emit()
        }
    }
}
