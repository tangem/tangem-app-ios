//
//  RepeatedTaskProcessorTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemFoundation

// [REDACTED_TODO_COMMENT]
// These tests wait out real milliseconds; an injected clock would let them step time instead.
// [REDACTED_INFO]
@Suite("RepeatedTaskProcessor tests")
struct RepeatedTaskProcessorTests {
    @Test("Runs the action again and again until cancelled")
    func runsUntilCancelled() async throws {
        let processor = RepeatedTaskProcessor(duration: .milliseconds(10))
        let counter = Counter()

        await processor.start { await counter.start() }
        try await counter.wait(untilStartsReach: 3)
        await processor.cancel()

        let startsAtCancel = await counter.starts
        try await Task.sleep(for: .milliseconds(50))

        #expect(await counter.starts == startsAtCancel)
        #expect(await processor.isRunning == false)
    }

    @Test("Waits out the interval before the first run")
    func firstRunWaitsForTheInterval() async throws {
        let processor = RepeatedTaskProcessor(duration: .milliseconds(200))
        let counter = Counter()

        await processor.start { await counter.start() }
        try await Task.sleep(for: .milliseconds(20))

        #expect(await counter.starts == 0)
        #expect(await processor.isRunning)

        await processor.cancel()
    }

    @Test("Runs the action right away when started with runsImmediately")
    func firstRunIsImmediate() async throws {
        let processor = RepeatedTaskProcessor(duration: .milliseconds(200))
        let counter = Counter()

        await processor.start(runsImmediately: true) { await counter.start() }
        try await Task.sleep(for: .milliseconds(20))

        #expect(await counter.starts == 1)

        await processor.cancel()
    }

    @Test("A run that outlasts the interval holds the next one back rather than overlapping it")
    func runsNeverOverlap() async throws {
        let processor = RepeatedTaskProcessor(duration: .milliseconds(10))
        let counter = Counter()

        await processor.start {
            await counter.start()
            try? await Task.sleep(for: .milliseconds(30))
            await counter.finish()
        }
        try await counter.wait(untilStartsReach: 3)
        await processor.cancel()

        #expect(await counter.concurrentRunsHighWaterMark == 1)
    }

    @Test("A second start keeps the timer that is already ticking")
    func secondStartIsIgnored() async throws {
        let processor = RepeatedTaskProcessor(duration: .milliseconds(10))
        let first = Counter()
        let second = Counter()

        await processor.start { await first.start() }
        await processor.start { await second.start() }
        try await first.wait(untilStartsReach: 3)
        await processor.cancel()

        #expect(await second.starts == 0)
    }

    @Test("A cancelled processor can be started anew")
    func restartsAfterCancel() async throws {
        let processor = RepeatedTaskProcessor(duration: .milliseconds(10))
        let counter = Counter()

        await processor.start { await counter.start() }
        try await counter.wait(untilStartsReach: 1)
        await processor.cancel()

        let startsAtCancel = await counter.starts
        await processor.start { await counter.start() }
        try await counter.wait(untilStartsReach: startsAtCancel + 2)
        await processor.cancel()

        #expect(await counter.starts >= startsAtCancel + 2)
    }
}

// MARK: - Test helpers

extension RepeatedTaskProcessorTests {
    private actor Counter {
        private(set) var starts = 0
        private(set) var concurrentRunsHighWaterMark = 0

        private var runningCount = 0

        func start() {
            starts += 1
            runningCount += 1
            concurrentRunsHighWaterMark = max(concurrentRunsHighWaterMark, runningCount)
        }

        func finish() {
            runningCount -= 1
        }

        /// Polls rather than signals, so that a timer that never fires fails the test instead of hanging it.
        func wait(untilStartsReach expected: Int) async throws {
            for _ in 0 ..< 200 where starts < expected {
                try await Task.sleep(for: .milliseconds(10))
            }

            try #require(starts >= expected, "The action started \(starts) times, fewer than the \(expected) awaited")
        }
    }
}
