//
//  PollingServiceTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("PollingServiceTests")
struct PollingServiceTests {
    @Test("Chunked polling respects max concurrent requests")
    func chunkedPollRespectsMaxConcurrent() async throws {
        // Given
        let tracker = RequestTracker()

        let sut = PollingService<MockRequest, MockResponse>(
            request: { request in
                await tracker.recordStart(id: request.id)
                try? await Task.sleep(for: .milliseconds(50))
                await tracker.recordEnd(id: request.id)
                return MockResponse(id: request.id)
            },
            shouldStopPolling: { _ in true },
            hasChanges: { _, _ in false },
            pollingInterval: 100,
            maxConcurrentRequests: 3
        )

        // 7 requests → should be processed in chunks of 3, 3, 1
        let requests = (0 ..< 7).map { MockRequest(id: "\($0)") }

        // When
        await sut.startPolling(requests: requests, force: true)
        try await Task.sleep(for: .milliseconds(500))
        await sut.cancelTask()

        // Then
        let events = await tracker.events
        #expect(!events.isEmpty, "Expected some events to be recorded")

        let maxConcurrent = await tracker.maxConcurrentRequests
        #expect(maxConcurrent <= 3, "Expected max 3 concurrent requests, got \(maxConcurrent)")
        #expect(maxConcurrent > 1, "Expected some concurrency, got \(maxConcurrent)")

        let completedCount = await tracker.completedCount
        #expect(completedCount == 7, "Expected all 7 requests to complete, got \(completedCount)")
    }

    @Test("Unlimited polling fires all requests concurrently")
    func unlimitedPollFiresConcurrently() async throws {
        // Given
        let tracker = RequestTracker()

        let sut = PollingService<MockRequest, MockResponse>(
            request: { request in
                await tracker.recordStart(id: request.id)
                try? await Task.sleep(for: .milliseconds(100))
                await tracker.recordEnd(id: request.id)
                return MockResponse(id: request.id)
            },
            shouldStopPolling: { _ in true },
            hasChanges: { _, _ in false },
            pollingInterval: 100
        )

        let requests = (0 ..< 5).map { MockRequest(id: "\($0)") }

        // When
        await sut.startPolling(requests: requests, force: true)
        try await Task.sleep(for: .milliseconds(300))
        await sut.cancelTask()

        // Then
        let maxConcurrent = await tracker.maxConcurrentRequests
        #expect(maxConcurrent > 3, "Expected more than 3 concurrent requests, got \(maxConcurrent)")
    }

    @Test("Chunked polling respects cancellation between chunks")
    func chunkedPollRespectsCancellation() async throws {
        // Given
        let tracker = RequestTracker()

        let sut = PollingService<MockRequest, MockResponse>(
            request: { request in
                await tracker.recordStart(id: request.id)
                try? await Task.sleep(for: .milliseconds(100))
                await tracker.recordEnd(id: request.id)
                return MockResponse(id: request.id)
            },
            shouldStopPolling: { _ in false },
            hasChanges: { _, _ in false },
            pollingInterval: 100,
            maxConcurrentRequests: 2
        )

        // 10 requests in chunks of 2 → 5 chunks × 100ms = 500ms total
        let requests = (0 ..< 10).map { MockRequest(id: "\($0)") }

        // When
        await sut.startPolling(requests: requests, force: true)
        // Cancel after ~150ms — should only complete first chunk (2) and maybe start second
        try await Task.sleep(for: .milliseconds(150))
        await sut.cancelTask()

        // Then
        let completedCount = await tracker.completedCount
        #expect(completedCount < 10, "Expected fewer than 10 completed requests (got \(completedCount)), cancellation should have stopped early")
    }

    @Test("Chunked polling with chunk size 1 is fully sequential")
    func chunkSizeOneIsSequential() async throws {
        // Given
        let tracker = RequestTracker()

        let sut = PollingService<MockRequest, MockResponse>(
            request: { request in
                await tracker.recordStart(id: request.id)
                try? await Task.sleep(for: .milliseconds(50))
                await tracker.recordEnd(id: request.id)
                return MockResponse(id: request.id)
            },
            shouldStopPolling: { _ in true },
            hasChanges: { _, _ in false },
            pollingInterval: 100,
            maxConcurrentRequests: 1
        )

        let requests = (0 ..< 3).map { MockRequest(id: "\($0)") }

        // When
        await sut.startPolling(requests: requests, force: true)
        try await Task.sleep(for: .milliseconds(300))
        await sut.cancelTask()

        // Then
        let maxConcurrent = await tracker.maxConcurrentRequests
        #expect(maxConcurrent == 1, "Expected max 1 concurrent request, got \(maxConcurrent)")
    }
}

// MARK: - Test Helpers

private struct MockRequest: Identifiable, Sendable {
    let id: String
}

private struct MockResponse: Identifiable, Sendable {
    let id: String
}

private actor RequestTracker {
    struct Event {
        let id: String
        let type: EventType
        let timestamp: ContinuousClock.Instant

        enum EventType {
            case start
            case end
        }
    }

    private(set) var events: [Event] = []
    private var inFlightCount = 0
    private(set) var maxConcurrentRequests = 0
    private(set) var completedCount = 0

    func recordStart(id: String) {
        events.append(Event(id: id, type: .start, timestamp: .now))
        inFlightCount += 1
        maxConcurrentRequests = max(maxConcurrentRequests, inFlightCount)
    }

    func recordEnd(id: String) {
        events.append(Event(id: id, type: .end, timestamp: .now))
        inFlightCount -= 1
        completedCount += 1
    }
}
