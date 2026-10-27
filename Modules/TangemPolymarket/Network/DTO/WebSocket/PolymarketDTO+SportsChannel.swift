//
//  PolymarketDTO+SportsChannel.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension PolymarketDTO {
    struct SportsChannelGame: Decodable {
        let gameId: Int
        let leagueAbbreviation: String
        let homeTeam: String
        let awayTeam: String
        let status: String
        let score: String?
        let period: String?
        let live: Bool
        let ended: Bool
    }
}
