//
//  PolymarketForegroundPollerTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("Polymarket foreground poller", .timeLimit(.minutes(1)))
@MainActor
struct PolymarketForegroundPollerTests {
    @Test("The poller ticks on its interval without ticking at start")
    func ticksOnInterval() async {
        let context = Self.makeSUT()

        #expect(await context.next() == .parked)

        context.delayProvider.releaseParkedWaits()
        #expect(await context.next(2) == [.tick, .parked])

        context.delayProvider.releaseParkedWaits()
        #expect(await context.next(2) == [.tick, .parked])
    }

    @Test("Going to background pauses the poller, coming back ticks at once and resumes")
    func pausesInBackground() async {
        let context = Self.makeSUT()
        #expect(await context.next() == .parked)

        context.appState.enterBackground()
        #expect(await context.next(2) == [.cancelled, .pause])

        context.appState.enterForeground()
        #expect(await context.next(2) == [.tick, .parked])

        context.delayProvider.releaseParkedWaits()
        #expect(await context.next(2) == [.tick, .parked])
    }

    @Test("A suspended poller stops ticking, stays quiet on coming back from background and ticks at once when resumed")
    func pausesWhileSuspended() async {
        let context = Self.makeSUT()
        #expect(await context.next() == .parked)

        context.poller.setSuspended(true)
        #expect(await context.next(2) == [.cancelled, .pause])

        context.appState.enterBackground()
        context.appState.enterForeground()
        #expect(await context.next() == .pause)

        context.poller.setSuspended(false)
        #expect(await context.next(2) == [.tick, .parked])

        context.delayProvider.releaseParkedWaits()
        #expect(await context.next(2) == [.tick, .parked])
    }

    @Test("Suspending again right after resuming drops the queued tick")
    func quickResumeAndSuspendDoesNotTick() async {
        let context = Self.makeSUT()
        #expect(await context.next() == .parked)

        context.poller.setSuspended(true)
        #expect(await context.next(2) == [.cancelled, .pause])

        context.poller.setSuspended(false)
        context.poller.setSuspended(true)
        #expect(await context.next() == .pause)

        context.poller.setSuspended(false)
        #expect(await context.next(2) == [.tick, .parked])
    }
}

// MARK: - Helpers

private extension PolymarketForegroundPollerTests {
    enum Event: Equatable {
        case tick
        case pause
        case parked
        case cancelled
    }

    @MainActor
    final class Context {
        let poller: PolymarketForegroundPoller
        let appState: AppStateObserverStub
        let delayProvider: ParkingDelayProvider

        private var iterator: AsyncStream<Event>.Iterator

        init(
            poller: PolymarketForegroundPoller,
            appState: AppStateObserverStub,
            delayProvider: ParkingDelayProvider,
            events: AsyncStream<Event>
        ) {
            self.poller = poller
            self.appState = appState
            self.delayProvider = delayProvider
            iterator = events.makeAsyncIterator()
        }

        func next() async -> Event? {
            await next(1).first
        }

        func next(_ count: Int) async -> [Event] {
            var iterator = iterator
            var events: [Event] = []

            for _ in 0 ..< count {
                guard let event = await iterator.next() else { break }

                events.append(event)
            }

            self.iterator = iterator
            return events
        }
    }

    static func makeSUT() -> Context {
        let (events, continuation) = AsyncStream<Event>.makeStream()
        let appState = AppStateObserverStub()
        let delayProvider = ParkingDelayProvider { event in
            switch event {
            case .parked: continuation.yield(.parked)
            case .cancelled: continuation.yield(.cancelled)
            }
        }

        let poller = PolymarketForegroundPoller(interval: 10, appStateObserver: appState, delayProvider: delayProvider)

        poller.start(
            onTick: { continuation.yield(.tick) },
            onPause: { continuation.yield(.pause) }
        )

        return Context(poller: poller, appState: appState, delayProvider: delayProvider, events: events)
    }
}
