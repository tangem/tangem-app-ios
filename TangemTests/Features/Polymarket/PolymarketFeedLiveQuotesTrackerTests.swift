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

@Suite("Polymarket feed live quotes tracker")
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

        env.sut.update(events: events, visibleEventIDs: ["e7"])

        let expected = Set([2, 3, 5, 6, 7, 8, 9, 10, 11, 12].flatMap { Fixtures.assetIds(of: events[$0], markets: 2) })
        #expect(env.sut.trackedAssetIds == expected)

        try await settle { env.source.streams.count == 1 }
        #expect(env.source.streams.first?.assetIds == expected)
    }

    @Test("Updates while paused are ignored until the tracker is resumed")
    func pausedTrackerIgnoresUpdates() async throws {
        let env = makeSUT()
        let event = Fixtures.event(id: "a")

        env.sut.update(events: [event], visibleEventIDs: ["a"])
        try await settle { env.source.streams.count == 1 }

        env.sut.pause()
        #expect(env.sut.trackedAssetIds.isEmpty)
        try await settle { env.source.streams[0].isCancelled }

        env.sut.update(events: [event], visibleEventIDs: ["a"])
        try await drain()

        #expect(env.sut.trackedAssetIds.isEmpty)
        #expect(env.source.streams.count == 1)

        env.sut.resume()
        env.sut.update(events: [event], visibleEventIDs: ["a"])

        #expect(env.sut.trackedAssetIds == Fixtures.assetIds(of: event))
        try await settle { env.source.streams.count == 2 }
    }

    @Test("A new set of outcomes opens its stream before the previous one is closed")
    func newStreamOpensBeforeThePreviousCloses() async throws {
        let env = makeSUT()
        let first = Fixtures.event(id: "a")
        let second = Fixtures.event(id: "b")

        env.sut.update(events: [first], visibleEventIDs: ["a"])
        try await settle { env.source.streams.count == 1 }

        env.sut.update(events: [first, second], visibleEventIDs: ["a", "b"])
        try await settle { env.source.streams.count == 2 }
        try await settle { env.source.streams[0].isCancelled }

        #expect(env.source.openStreamsAtRequest == [0, 1])
    }

    // MARK: - Batches

    @Test("Quotes arriving together leave in one batch with the latest quote of each outcome, later ones in the next batch")
    func quotesAreBatchedAndNothingIsLostOnFlush() async throws {
        let env = makeSUT()
        let event = Fixtures.event(id: "a")
        let yes = "a-m0-yes"
        let no = "a-m0-no"

        env.sut.update(events: [event], visibleEventIDs: ["a"])
        try await settle { env.source.streams.count == 1 }

        let stream = env.source.streams[0]
        stream.push(Fixtures.quote(yes, ask: "0.40"))
        stream.push(Fixtures.quote(no, ask: "0.60"))
        stream.push(Fixtures.quote(yes, ask: "0.41"))

        try await settle { env.recorder.updates.count == 1 }
        #expect(env.recorder.updates == [.quotes([yes: Fixtures.quote(yes, ask: "0.41"), no: Fixtures.quote(no, ask: "0.60")])])

        stream.push(Fixtures.quote(no, ask: "0.61"))

        try await settle { env.recorder.updates.count == 2 }
        #expect(env.recorder.updates.last == .quotes([no: Fixtures.quote(no, ask: "0.61")]))
    }

    @Test("A quote waiting for its batch is dropped when its outcome stops being tracked")
    func pendingQuoteOfUntrackedOutcomeIsDropped() async throws {
        let env = makeSUT()
        let dropped = Fixtures.event(id: "a")
        let kept = Fixtures.event(id: "b")

        env.sut.update(events: [dropped, kept], visibleEventIDs: ["a", "b"])
        try await settle { env.source.streams.count == 1 }

        env.source.streams[0].push(Fixtures.quote("a-m0-yes", ask: "0.40"))
        try await settle { env.source.streams[0].pulls >= 2 }

        env.sut.update(events: [Fixtures.event(id: "a", isLive: false), kept], visibleEventIDs: ["a", "b"])
        try await settle { env.source.streams.count == 2 }
        env.source.streams[1].push(Fixtures.quote("b-m0-yes", ask: "0.50"))

        try await settle { env.recorder.updates.count == 1 }
        #expect(env.recorder.updates == [.quotes(["b-m0-yes": Fixtures.quote("b-m0-yes", ask: "0.50")])])
    }

    // MARK: - Connection

    @Test("A quote the previous connection still delivers after it was lost never reaches the feed")
    func quoteFromALostConnectionIsDropped() async throws {
        let env = makeSUT()
        let yes = "a-m0-yes"

        try await env.connect()
        env.sut.update(events: [Fixtures.event(id: "a")], visibleEventIDs: ["a"])
        try await settle { env.source.streams.count == 1 }

        env.source.statuses.push(.waitingToReconnect)
        try await settle { env.recorder.updates == [.connectionLost] }
        try await settle { env.source.streams.count == 2 }
        #expect(env.source.streams[0].isCancelled)

        env.source.streams[0].push(Fixtures.quote(yes, ask: "0.40"))
        env.source.streams[1].push(Fixtures.quote(yes, ask: "0.45"))

        try await settle { env.recorder.updates.count == 2 }
        #expect(env.recorder.updates == [.connectionLost, .quotes([yes: Fixtures.quote(yes, ask: "0.45")])])
    }

    @Test("Quotes the old reader already holds when the connection is lost never reach the feed")
    func quotesBufferedBeforeTheLossAreDropped() async throws {
        let statuses = PolymarketLiveStreamSpy<PolymarketWebSocketConnectionStatus>()
        let source = BufferedQuotesSourceSpy()
        let sut = PolymarketFeedLiveQuotesTracker(
            quotes: { _ in source.makeStream() },
            statusChanges: { statuses.makeStream() }
        )
        let recorder = UpdatesRecorder(updates: sut.updates)

        statuses.push(.connected)
        try await settle { statuses.pulls >= 2 }
        sut.update(events: [Fixtures.event(id: "a")], visibleEventIDs: ["a"])
        try await settle { source.continuations.count == 1 }
        try await drain()

        statuses.push(.waitingToReconnect)
        source.continuations[0].yield(Fixtures.quote("a-m0-no", ask: "0.60"))
        source.continuations[0].yield(Fixtures.quote("a-m0-no", ask: "0.61"))

        try await settle { source.continuations.count == 2 }
        source.continuations[1].yield(Fixtures.quote("a-m0-yes", ask: "0.45"))

        try await settle { recorder.updates.count == 2 }
        #expect(recorder.updates == [.connectionLost, .quotes(["a-m0-yes": Fixtures.quote("a-m0-yes", ask: "0.45")])])
    }

    @Test("A stopped socket stops reading quotes without opening a new stream")
    func stoppedSocketDoesNotReopenTheStream() async throws {
        let env = makeSUT()

        try await env.connect()
        env.sut.update(events: [Fixtures.event(id: "a")], visibleEventIDs: ["a"])
        try await settle { env.source.streams.count == 1 }

        env.source.statuses.push(.stopped)
        try await settle { env.recorder.updates == [.connectionLost] }
        try await drain()

        #expect(env.source.streams.count == 1)
        #expect(env.source.streams[0].isCancelled)
    }

    @Test("A lost connection is reported once however many statuses it goes through")
    func lostConnectionIsReportedOnce() async throws {
        let env = makeSUT()

        try await env.connect()
        env.source.statuses.push(.waitingToReconnect)
        env.source.statuses.push(.connecting)
        env.source.statuses.push(.waitingToReconnect)
        try await settle { env.source.statuses.pulls >= 5 }
        try await drain()

        #expect(env.recorder.updates == [.connectionLost])

        env.source.statuses.push(.connected)
        env.source.statuses.push(.waitingToReconnect)
        try await settle { env.recorder.updates == [.connectionLost, .connectionLost] }
    }
}

// MARK: - Helpers

private extension PolymarketFeedLiveQuotesTrackerTests {
    func makeSUT() -> Environment {
        let source = PolymarketLiveQuotesSourceSpy()
        let sut = source.makeTracker()

        return Environment(sut: sut, source: source, recorder: UpdatesRecorder(updates: sut.updates))
    }

    @MainActor
    struct Environment {
        let sut: PolymarketFeedLiveQuotesTracker
        let source: PolymarketLiveQuotesSourceSpy
        let recorder: UpdatesRecorder

        func connect() async throws {
            let pulls = source.statuses.pulls
            source.statuses.push(.connected)
            try await settle { source.statuses.pulls > max(pulls, 1) }
        }
    }
}

// MARK: - Doubles

private final class BufferedQuotesSourceSpy: Sendable {
    private let state = OSAllocatedUnfairLock(initialState: [AsyncStream<PolymarketOutcomeQuote>.Continuation]())

    var continuations: [AsyncStream<PolymarketOutcomeQuote>.Continuation] {
        state.withLock { $0 }
    }

    func makeStream() -> AsyncStream<PolymarketOutcomeQuote> {
        let (stream, continuation) = AsyncStream.makeStream(of: PolymarketOutcomeQuote.self)
        state.withLock { $0.append(continuation) }
        return stream
    }
}

@MainActor
private final class UpdatesRecorder {
    private(set) var updates: [RecordedUpdate] = []

    init(updates: AsyncStream<PolymarketFeedLiveQuotesTracker.Update>) {
        Task { [weak self] in
            for await update in updates {
                self?.updates.append(RecordedUpdate(update))
            }
        }
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
