//
//  PolymarketLiveGame.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public struct PolymarketLiveGame: Hashable, Sendable {
    public let gameId: Int
    public let leagueAbbreviation: String
    public let homeTeam: String
    public let awayTeam: String
    public let status: String
    public let score: String?
    public let period: String?
    public let isLive: Bool
    public let hasEnded: Bool

    public init(
        gameId: Int,
        leagueAbbreviation: String,
        homeTeam: String,
        awayTeam: String,
        status: String,
        score: String?,
        period: String?,
        isLive: Bool,
        hasEnded: Bool
    ) {
        self.gameId = gameId
        self.leagueAbbreviation = leagueAbbreviation
        self.homeTeam = homeTeam
        self.awayTeam = awayTeam
        self.status = status
        self.score = score
        self.period = period
        self.isLive = isLive
        self.hasEnded = hasEnded
    }
}
