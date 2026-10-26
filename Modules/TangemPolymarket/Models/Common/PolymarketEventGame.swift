//
//  PolymarketEventGame.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct PolymarketEventGame: Hashable, Sendable {
    public let gameId: String
    public let score: PolymarketGameScore
    public let period: String?
    public let hasEnded: Bool

    public init(gameId: String, score: PolymarketGameScore, period: String?, hasEnded: Bool) {
        self.gameId = gameId
        self.score = score
        self.period = period
        self.hasEnded = hasEnded
    }
}
