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

    var subscribing: (any PolymarketWebSocketSubscribing<String>)? {
        nil
    }

    var silenceTimeout: Duration? {
        nil
    }

    func updates(from message: WebSocketMessage) throws -> [PolymarketLiveGame] {
        guard case .text(let text) = message, !text.isEmpty else {
            return []
        }

        let game = try decoder.decode(PolymarketDTO.SportsChannelGame.self, from: Data(text.utf8))

        guard let gameId = game.gameId else {
            return []
        }

        return [
            PolymarketLiveGame(
                gameId: String(gameId),
                score: PolymarketGameScore(parsing: game.score, period: game.period),
                period: game.period,
                isLive: game.live,
                hasEnded: game.ended
            ),
        ]
    }

    func topic(of update: PolymarketLiveGame) -> String {
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
