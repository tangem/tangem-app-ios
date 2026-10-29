//
//  PolymarketFeedLiveQuotesTrackerTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
import TangemPolymarket
@testable import Tangem

@Suite("Polymarket feed live quotes tracker", .timeLimit(.minutes(1)))
@MainActor
struct PolymarketFeedLiveQuotesTrackerTests {
    private typealias Fixtures = PolymarketLiveQuotesFixtures

    // MARK: - What is tracked

    @Test("Only live events within five of the visible ones are tracked, with the markets their cards show")
    func tracksLiveEventsAroundTheVisibleOnes() async throws {
        let env = makeSUT()
        let events = (0 ..< 15).map { index in
            Fixtures.event(id: "e\(index)", isLive: index != 4, marketCount: index == 6 ? 3 : 1)
        }

        env.sut.update(events: events, visibleEventIDs: ["e7"], isLive: \.isLive)

        let expected = Set([2, 3, 5, 6, 7, 8, 9, 10, 11, 12].flatMap { Fixtures.assetIds(of: events[$0], markets: 2) })
        #expect(env.sut.trackedAssetIds == expected)
        #expect(try await env.source.requests.next().assetIds == expected)
    }

    @Test("A soccer match also follows the Yes of its draw, which its card shows though the two displayed markets leave it out")
    func drawOutsideTheDisplayedMarketsIsTracked() async throws {
        let env = makeSUT()
        let match = PolymarketLiveGamesFixtures.soccer()

        env.sut.update(events: [match], visibleEventIDs: [match.id], isLive: \.isLive)

        #expect(env.sut.trackedAssetIds.contains("1201001-draw-yes"))
        #expect(try await env.source.requests.next().assetIds.contains("1201001-draw-yes"))
    }

    @Test("A match whose page left markets out follows only the markets its card shows")
    func partialMatchFollowsOnlyItsDisplayedMarkets() {
        let env = makeSUT()
        let match = PolymarketLiveGamesFixtures.soccer(totalMarketsCount: 4)

        env.sut.update(events: [match], visibleEventIDs: [match.id], isLive: \.isLive)

        #expect(env.sut.trackedAssetIds == ["1201001-ars-yes", "1201001-ars-no", "1201001-che-yes", "1201001-che-no"])
    }

    @Test("Updates while paused are ignored until the tracker is resumed")
    func pausedTrackerIgnoresUpdates() async throws {
        let env = makeSUT()
        let paused = Fixtures.event(id: "a")
        let resumed = Fixtures.event(id: "b")

        env.sut.update(events: [paused], visibleEventIDs: ["a"], isLive: \.isLive)
        let first = try await env.source.requests.next()

        env.sut.pause()
        #expect(env.sut.trackedAssetIds.isEmpty)
        try await first.cancelled.next()

        env.sut.update(events: [paused], visibleEventIDs: ["a"], isLive: \.isLive)
        #expect(env.sut.trackedAssetIds.isEmpty)

        env.sut.resume()
        env.sut.update(events: [resumed], visibleEventIDs: ["b"], isLive: \.isLive)

        #expect(env.sut.trackedAssetIds == Fixtures.assetIds(of: resumed))
        #expect(try await env.source.requests.next().assetIds == Fixtures.assetIds(of: resumed))
    }

    @Test("A new set of outcomes opens its stream before the previous one is closed")
    func newStreamOpensBeforeThePreviousCloses() async throws {
        let env = makeSUT()
        let first = Fixtures.event(id: "a")
        let second = Fixtures.event(id: "b")

        env.sut.update(events: [first], visibleEventIDs: ["a"], isLive: \.isLive)
        let firstStream = try await env.source.requests.next()

        env.sut.update(events: [first, second], visibleEventIDs: ["a", "b"], isLive: \.isLive)
        try await env.source.requests.next()
        try await firstStream.cancelled.next()

        #expect(env.source.openStreamsAtRequest == [0, 1])
    }

    // MARK: - Batches

    @Test("Every batch carries the latest quote of each outcome, and a quote arriving after a flush leaves in the next batch")
    func quotesAreBatchedAndNothingIsLostOnFlush() async throws {
        let env = makeSUT()
        let event = Fixtures.event(id: "a")
        let yes = "a-m0-yes"
        let no = "a-m0-no"

        env.sut.update(events: [event], visibleEventIDs: ["a"], isLive: \.isLive)
        let stream = try await env.source.requests.next()

        stream.push(Fixtures.quote(yes, ask: "0.40"))
        stream.push(Fixtures.quote(no, ask: "0.60"))
        stream.push(Fixtures.quote(yes, ask: "0.41"))

        var delivered: [String: PolymarketOutcomeQuote] = [:]
        let latest = [yes: Fixtures.quote(yes, ask: "0.41"), no: Fixtures.quote(no, ask: "0.60")]

        while delivered != latest {
            guard case .quotes(let batch) = try await env.flushNextBatch() else {
                Issue.record("Only quotes were expected")
                return
            }

            #expect(delivered[yes] != Fixtures.quote(yes, ask: "0.41") || batch[yes] == nil)
            delivered.merge(batch) { _, new in new }
        }

        stream.push(Fixtures.quote(no, ask: "0.61"))

        #expect(try await env.flushNextBatch() == .quotes([no: Fixtures.quote(no, ask: "0.61")]))
    }

    @Test("A quote waiting for its batch is dropped when its outcome stops being tracked")
    func pendingQuoteOfUntrackedOutcomeIsDropped() async throws {
        let env = makeSUT()
        let dropped = Fixtures.event(id: "a")
        let kept = Fixtures.event(id: "b")

        env.sut.update(events: [dropped, kept], visibleEventIDs: ["a", "b"], isLive: \.isLive)
        let firstStream = try await env.source.requests.next()

        firstStream.push(Fixtures.quote("a-m0-yes", ask: "0.40"))
        try await env.delay.waitUntilParked(Constants.batchInterval)

        env.sut.update(events: [Fixtures.event(id: "a", isLive: false), kept], visibleEventIDs: ["a", "b"], isLive: \.isLive)
        env.delay.resume()

        let secondStream = try await env.source.requests.next()
        secondStream.push(Fixtures.quote("b-m0-yes", ask: "0.50"))

        #expect(try await env.flushNextBatch() == .quotes(["b-m0-yes": Fixtures.quote("b-m0-yes", ask: "0.50")]))
    }

    // MARK: - Connection

    @Test("A quote the previous connection still delivers after it was lost never reaches the feed")
    func quoteFromALostConnectionIsDropped() async throws {
        let env = makeSUT()
        let yes = "a-m0-yes"

        try await env.connect()
        env.sut.update(events: [Fixtures.event(id: "a")], visibleEventIDs: ["a"], isLive: \.isLive)
        let lostStream = try await env.source.requests.next()

        env.source.statuses.push(.waitingToReconnect)
        #expect(try await env.updates.next() == .connectionLost)
        let freshStream = try await env.source.requests.next()
        try await lostStream.cancelled.next()

        lostStream.push(Fixtures.quote(yes, ask: "0.40"))
        freshStream.push(Fixtures.quote(yes, ask: "0.45"))

        #expect(try await env.flushNextBatch() == .quotes([yes: Fixtures.quote(yes, ask: "0.45")]))
    }

    @Test("Quotes the old reader already holds when the connection is lost never reach the feed")
    func quotesBufferedBeforeTheLossAreDropped() async throws {
        let statuses = PolymarketLiveStreamSpy<PolymarketWebSocketConnectionStatus>()
        let source = BufferedQuotesSourceSpy()
        let delay = PolymarketSteppedDelayProvider()
        let sut = PolymarketFeedLiveQuotesTracker(
            quotes: { @MainActor _ in source.makeStream() },
            statusChanges: { statuses.makeStream() },
            delayProvider: delay
        )
        let updates = PolymarketTestSignal<RecordedUpdate>()
        updates.record(sut.updates, transform: { RecordedUpdate($0) })

        statuses.push(.connected)
        try await statuses.waitForPulls(2)
        sut.update(events: [Fixtures.event(id: "a")], visibleEventIDs: ["a"], isLive: \.isLive)
        let lost = try await source.requests.next()

        statuses.push(.waitingToReconnect)
        lost.yield(Fixtures.quote("a-m0-no", ask: "0.60"))
        lost.yield(Fixtures.quote("a-m0-no", ask: "0.61"))

        #expect(try await updates.next() == .connectionLost)
        let fresh = try await source.requests.next()
        fresh.yield(Fixtures.quote("a-m0-yes", ask: "0.45"))
        try await delay.waitUntilParked(Constants.batchInterval)

        delay.resume()
        #expect(try await updates.next() == .quotes(["a-m0-yes": Fixtures.quote("a-m0-yes", ask: "0.45")]))
        withExtendedLifetime(sut) {}
    }
}

// MARK: - Helpers

private extension PolymarketFeedLiveQuotesTrackerTests {
    func makeSUT() -> Environment {
        let source = PolymarketLiveQuotesSourceSpy()
        let delay = PolymarketSteppedDelayProvider()
        let sut = source.makeTracker(delayProvider: delay)
        let updates = PolymarketTestSignal<RecordedUpdate>()
        updates.record(sut.updates, transform: { RecordedUpdate($0) })

        return Environment(sut: sut, source: source, delay: delay, updates: updates)
    }

    @MainActor
    struct Environment {
        let sut: PolymarketFeedLiveQuotesTracker
        let source: PolymarketLiveQuotesSourceSpy
        let delay: PolymarketSteppedDelayProvider
        let updates: PolymarketTestSignal<RecordedUpdate>

        func connect() async throws {
            source.statuses.push(.connected)
            try await source.statuses.waitForPulls(2)
        }

        func flushNextBatch() async throws -> RecordedUpdate {
            try await delay.waitUntilParked(Constants.batchInterval)
            delay.resume()
            return try await updates.next()
        }
    }

    enum Constants {
        static let batchInterval: TimeInterval = 0.3
    }
}

// MARK: - Doubles

private final class BufferedQuotesSourceSpy: Sendable {
    let requests = PolymarketTestSignal<AsyncStream<PolymarketOutcomeQuote>.Continuation>()

    func makeStream() -> AsyncStream<PolymarketOutcomeQuote> {
        let (stream, continuation) = AsyncStream.makeStream(of: PolymarketOutcomeQuote.self)
        requests.send(continuation)
        return stream
    }
}

private enum RecordedUpdate: Equatable {
    case quotes([String: PolymarketOutcomeQuote])
    case connectionLost

    init(_ update: PolymarketFeedLiveQuotesTracker.Update) {
        switch update {
        case .quotes(let batch):
            self = .quotes(batch.quotesByAssetId)
        case .connectionLost:
            self = .connectionLost
        }
    }
}
