//
//  PolymarketForegroundPollerTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import UIKit
@testable import Tangem

@Suite("Polymarket foreground poller")
@MainActor
struct PolymarketForegroundPollerTests {
    @Test("The poller ticks on its interval without ticking at start")
    func ticksOnInterval() async throws {
        let context = Self.makeSUT()

        #expect(context.log.ticks == 0)

        try await settle { context.log.ticks >= 2 }
    }

    @Test("Going to background pauses the poller, coming back ticks at once and resumes")
    func pausesInBackground() async throws {
        let context = Self.makeSUT(interval: 0.2)

        try await settle { context.log.ticks >= 1 }

        context.notificationCenter.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        try await settle { context.log.pauses == 1 }

        let ticksBeforeBackground = context.log.ticks
        try await Task.sleep(nanoseconds: 500_000_000)
        #expect(context.log.ticks == ticksBeforeBackground)

        context.notificationCenter.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        try await settle { context.log.ticks > ticksBeforeBackground }

        try await settle { context.log.ticks >= ticksBeforeBackground + 2 }
        withExtendedLifetime(context.poller) {}
    }

    @Test("A suspended poller stops ticking, stays quiet on coming back from background and ticks at once when resumed")
    func pausesWhileSuspended() async throws {
        let context = Self.makeSUT(interval: 0.2)

        try await settle { context.log.ticks >= 1 }

        context.poller.setSuspended(true)
        #expect(context.log.pauses == 1)

        let ticksBeforeSuspension = context.log.ticks
        context.notificationCenter.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        context.notificationCenter.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        try await Task.sleep(nanoseconds: 500_000_000)
        #expect(context.log.ticks == ticksBeforeSuspension)

        context.poller.setSuspended(false)
        try await settle { context.log.ticks > ticksBeforeSuspension }

        try await settle { context.log.ticks >= ticksBeforeSuspension + 2 }
    }

    @Test("Suspending again right after resuming drops the queued tick")
    func quickResumeAndSuspendDoesNotTick() async throws {
        let context = Self.makeSUT(interval: 0.2)

        try await settle { context.log.ticks >= 1 }

        context.poller.setSuspended(true)
        let ticksBeforeSuspension = context.log.ticks

        context.poller.setSuspended(false)
        context.poller.setSuspended(true)
        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(context.log.ticks == ticksBeforeSuspension)
        #expect(context.log.pauses == 2)
    }
}

// MARK: - Helpers

private extension PolymarketForegroundPollerTests {
    struct Context {
        let poller: PolymarketForegroundPoller
        let log: PollLog
        let notificationCenter: NotificationCenter
    }

    static func makeSUT(interval: TimeInterval = 0.02) -> Context {
        let notificationCenter = NotificationCenter()
        let poller = PolymarketForegroundPoller(interval: interval, notificationCenter: notificationCenter)
        let log = PollLog()

        poller.start(
            onTick: { log.ticks += 1 },
            onPause: { log.pauses += 1 }
        )

        return Context(poller: poller, log: log, notificationCenter: notificationCenter)
    }
}

// MARK: - Doubles

@MainActor
private final class PollLog {
    var ticks = 0
    var pauses = 0
}
