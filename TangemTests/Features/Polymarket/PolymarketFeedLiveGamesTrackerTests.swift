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

@Suite("Polymarket feed live games tracker")
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

        try await settle { env.recorder.updates.count == 2 }
        try await drain()
        #expect(env.recorder.updates == [.game(frame), .game(next)])
    }

    @Test("A repeat of the last state still restarts the ten-minute silence countdown")
    @MainActor
    func repeatRestartsTheSilenceCountdown() async throws {
        let env = try await makeSUT()
        let frame = Fixtures.liveGame(Constants.gameId, score: "98-101")

        env.stream.push(frame)
        try await settle { env.delay.parkedCount == 1 }
        env.stream.push(frame)

        try await settle { env.delay.heldWaits.count == 2 }
        try await drain()
        #expect(env.delay.heldWaits == [Constants.silenceTimeout, Constants.silenceTimeout])
        #expect(env.delay.parkedCount == 1)
        #expect(env.recorder.updates == [.game(frame)])
    }

    @Test("A game silent for ten minutes falls back to REST, a repeat of its last state does not bring it back, a changed frame does")
    @MainActor
    func silentGameComesBackOnlyWithAChange() async throws {
        let env = try await makeSUT()
        let frame = Fixtures.liveGame(Constants.gameId, score: "98-101")
        let next = Fixtures.liveGame(Constants.gameId, score: "100-101")

        env.stream.push(frame)
        try await settle { env.delay.parkedCount == 1 }

        env.delay.resumeParkedWaits()
        try await settle { env.recorder.updates == [.game(frame), .silent(Constants.gameId)] }

        env.stream.push(frame)
        env.stream.push(next)

        try await settle { env.recorder.updates.count == 3 }
        try await drain()
        #expect(env.recorder.updates == [.game(frame), .silent(Constants.gameId), .game(next)])
    }

    @Test("A game that has not started yet gets the silence countdown too")
    @MainActor
    func notStartedGameHasASilenceCountdown() async throws {
        let env = try await makeSUT()
        let upcoming = Fixtures.liveGame(Constants.gameId, score: nil, period: nil, isLive: false)

        env.stream.push(upcoming)

        try await settle { env.delay.parkedCount == 1 }
    }

    @Test("A game that has ended keeps its final frame without a silence countdown")
    @MainActor
    func endedGameHasNoSilenceCountdown() async throws {
        let env = try await makeSUT()
        let final = Fixtures.liveGame(Constants.gameId, score: "110-104", period: "FT", isLive: false, hasEnded: true)

        env.stream.push(final)
        try await settle { env.recorder.updates == [.game(final)] }
        try await drain()

        #expect(env.delay.parkedCount == 0)
    }
}

// MARK: - Helpers

private extension PolymarketFeedLiveGamesTrackerTests {
    @MainActor
    func makeSUT() async throws -> Environment {
        let source = PolymarketLiveGamesSourceSpy()
        let delay = HoldingDelayProviderSpy(holdThreshold: 0)
        let sut = trackForMemoryLeaks(source.makeTracker(delayProvider: delay))
        let recorder = GameUpdatesRecorder(updates: sut.updates)

        sut.update(events: [Fixtures.basketball(gameId: Constants.gameId)])
        try await settle { source.streams.count == 1 }

        return Environment(sut: sut, source: source, delay: delay, recorder: recorder, stream: source.streams[0])
    }

    struct Environment {
        let sut: PolymarketFeedLiveGamesTracker
        let source: PolymarketLiveGamesSourceSpy
        let delay: HoldingDelayProviderSpy
        let recorder: GameUpdatesRecorder
        let stream: PolymarketLiveStreamSpy<PolymarketLiveGame>
    }

    enum Constants {
        static let gameId = "20023885"
        static let silenceTimeout: TimeInterval = 10 * 60
    }
}

// MARK: - Doubles

@MainActor
private final class GameUpdatesRecorder {
    private(set) var updates: [RecordedGameUpdate] = []

    init(updates: AsyncStream<PolymarketFeedLiveGamesTracker.Update>) {
        Task { [weak self] in
            for await update in updates {
                self?.updates.append(RecordedGameUpdate(update))
            }
        }
    }
}

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
