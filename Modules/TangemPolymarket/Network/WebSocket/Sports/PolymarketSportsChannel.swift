//
//  PolymarketSportsChannel.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemWebSocket

struct PolymarketSportsChannel: PolymarketWebSocketChannel {
    private let decoder = JSONDecoder()

    var url: URL {
        PolymarketHost.sportsChannel
    }

    var keepalive: PolymarketWebSocketConnectionManager.Keepalive {
        .protocolPing(interval: Constants.pingInterval, timeout: Constants.pingTimeout)
    }

    var subscribing: (any PolymarketWebSocketSubscribing<Int>)? {
        nil
    }

    func updates(from message: WebSocketMessage) throws -> [PolymarketLiveGame] {
        guard case .text(let text) = message, !text.isEmpty else {
            return []
        }

        let game = try decoder.decode(PolymarketDTO.SportsChannelGame.self, from: Data(text.utf8))

        return [
            PolymarketLiveGame(
                gameId: game.gameId,
                leagueAbbreviation: game.leagueAbbreviation,
                homeTeam: game.homeTeam,
                awayTeam: game.awayTeam,
                status: game.status,
                score: game.score,
                period: game.period,
                isLive: game.live,
                hasEnded: game.ended
            ),
        ]
    }

    func topic(of update: PolymarketLiveGame) -> Int {
        update.gameId
    }

    func value(applying update: PolymarketLiveGame, to previous: PolymarketLiveGame?) -> PolymarketLiveGame {
        update
    }
}

// MARK: - Constants

private enum Constants {
    static let pingInterval: Duration = .seconds(15)
    static let pingTimeout: Duration = .seconds(10)
}
