//
//  PolymarketFeedLiveGamesTrackerTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemPolymarket
import TangemTestKit
@testable import Tangem

@Suite("Polymarket feed live games tracker", .timeLimit(.minutes(1)))
final class PolymarketFeedLiveGamesTrackerTests: LeakTrackingTestSuite {
    private typealias Fixtures = PolymarketLiveGamesFixtures

    @Test("A frame repeating the last state is dropped, a frame with any change passes")
    @MainActor
    func repeatIsDroppedAndAChangePasses() async throws {
        let env = try await makeSUT()
        let frame = Fixtures.liveGame(Constants.gameId, score: "98-101")
        let next = Fixtures.liveGame(Constants.gameId, score: "100-101")

        env.stream.push(frame)
        env.stream.push(frame)
        env.stream.push(next)

        #expect(try await env.updates.next() == .game(frame))
        #expect(try await env.updates.next() == .game(next))
    }

    @Test("A repeat of the last state still restarts the ten-minute silence countdown")
    @MainActor
    func repeatRestartsTheSilenceCountdown() async throws {
        let env = try await makeSUT()
        let frame = Fixtures.liveGame(Constants.gameId, score: "98-101")
        let next = Fixtures.liveGame(Constants.gameId, score: "100-101")

        env.stream.push(frame)
        try await env.delay.nextWait(of: Constants.silenceTimeout)

        env.stream.push(frame)
        #expect(try await env.delay.cancellations.next() == Constants.silenceTimeout)
        try await env.delay.nextWait(of: Constants.silenceTimeout)
        #expect(env.delay.parkedWaits == [Constants.silenceTimeout])

        env.stream.push(next)
        #expect(try await env.updates.next() == .game(frame))
        #expect(try await env.updates.next() == .game(next))
    }

    @Test("A game silent for ten minutes falls back to REST, a repeat of its last state does not bring it back, a changed frame does")
    @MainActor
    func silentGameComesBackOnlyWithAChange() async throws {
        let env = try await makeSUT()
        let frame = Fixtures.liveGame(Constants.gameId, score: "98-101")
        let next = Fixtures.liveGame(Constants.gameId, score: "100-101")

        env.stream.push(frame)
        try await env.delay.nextWait(of: Constants.silenceTimeout)

        env.delay.resume()
        #expect(try await env.updates.next() == .game(frame))
        #expect(try await env.updates.next() == .silent(Constants.gameId))

        env.stream.push(frame)
        env.stream.push(next)

        #expect(try await env.updates.next() == .game(next))
    }

    @Test("A game that has not started yet gets the silence countdown too")
    @MainActor
    func notStartedGameHasASilenceCountdown() async throws {
        let env = try await makeSUT()
        let upcoming = Fixtures.liveGame(Constants.gameId, score: nil, period: nil, isLive: false)

        env.stream.push(upcoming)

        #expect(try await env.delay.nextWait() == Constants.silenceTimeout)
    }

    @Test("A game that has ended keeps its final frame without a silence countdown")
    @MainActor
    func endedGameHasNoSilenceCountdown() async throws {
        let env = try await makeSUT()
        let final = Fixtures.liveGame(Constants.gameId, score: "110-104", period: "FT", isLive: false, hasEnded: true)

        env.stream.push(final)
        #expect(try await env.updates.next() == .game(final))

        #expect(env.delay.requests.recorded.isEmpty)
    }
}

// MARK: - Helpers

private extension PolymarketFeedLiveGamesTrackerTests {
    @MainActor
    func makeSUT() async throws -> Environment {
        let source = PolymarketLiveGamesSourceSpy()
        let delay = PolymarketSteppedDelayProvider()
        let sut = trackForMemoryLeaks(source.makeTracker(delayProvider: delay))
        let updates = PolymarketTestSignal<RecordedGameUpdate>()
        updates.record(sut.updates, transform: { RecordedGameUpdate($0) })

        sut.update(events: [Fixtures.basketball(gameId: Constants.gameId)])
        let stream = try await source.requests.next()

        return Environment(sut: sut, delay: delay, updates: updates, stream: stream)
    }

    struct Environment {
        let sut: PolymarketFeedLiveGamesTracker
        let delay: PolymarketSteppedDelayProvider
        let updates: PolymarketTestSignal<RecordedGameUpdate>
        let stream: PolymarketLiveStreamSpy<PolymarketLiveGame>
    }

    enum Constants {
        static let gameId = "20023885"
        static let silenceTimeout: TimeInterval = 10 * 60
    }
}

// MARK: - Doubles

private enum RecordedGameUpdate: Equatable {
    case game(PolymarketLiveGame)
    case silent(String)
    case connectionLost
    case reconnected

    init(_ update: PolymarketFeedLiveGamesTracker.Update) {
        switch update {
        case .game(let game):
            self = .game(game)
        case .silent(let gameId):
            self = .silent(gameId)
        case .connectionLost:
            self = .connectionLost
        case .reconnected:
            self = .reconnected
        }
    }
}
