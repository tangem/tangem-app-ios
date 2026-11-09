//
//  PolymarketSportsChannelTests.swift
//  TangemPolymarketTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemWebSocket
@testable import TangemPolymarket

@Suite("Polymarket sports channel", .timeLimit(.minutes(1)))
struct PolymarketSportsChannelTests {
    @Test("A frame becomes a game with a string id")
    func frameBecomesAGame() throws {
        let updates = try makeSUT().updates(from: .text(Frames.dota))

        #expect(updates == [
            PolymarketLiveGame(
                gameId: "1752269",
                score: .esports(maps: PolymarketGameScore.Points(first: 0, second: 0), bestOf: 3),
                period: "1/3",
                isLive: true,
                hasEnded: false
            ),
        ])
    }

    @Test("Frames reach readers by game id, and a quiet sports socket is never torn down by the silence watchdog")
    func gamesAreRoutedByIdWithoutASilenceWatchdog() throws {
        let sut = makeSUT()
        let game = try #require(try sut.updates(from: .text(Frames.dota)).first)

        #expect(sut.topic(of: game) == "1752269")
        #expect(sut.silenceTimeout == nil)
    }

    @Test("A frame without a game id, as cricket sends them, is skipped without an error")
    func frameWithoutGameIdIsSkipped() throws {
        #expect(try makeSUT().updates(from: .text(Frames.cricket)).isEmpty)
    }
}

// MARK: - Helpers

private extension PolymarketSportsChannelTests {
    func makeSUT() -> PolymarketSportsChannel {
        PolymarketSportsChannel()
    }

    enum Frames {
        static let dota = """
        {"gameId":1752269,"leagueAbbreviation":"dota2","homeTeam":"Korb3n Team","awayTeam":"Stariy bog Team","status":"running","score":"000-000|0-0|Bo3","period":"1/3","live":true,"ended":false}
        """

        static let cricket = """
        {"leagueAbbreviation":"ipl","homeTeam":"Mumbai Indians","awayTeam":"Chennai Super Kings","status":"running","score":"145/3","period":"1st","live":true,"ended":false}
        """
    }
}
