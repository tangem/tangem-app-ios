//
//  PolymarketLiveGameCardModel.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public extension PolymarketLiveGameCard {
    struct Model: Equatable {
        public let id: String

        public let title: String
        public let category: PolymarketEventCard.Category?
        public let volumeText: String?
        public let home: Team
        public let away: Team
        public let score: Score?
        public let showsLiveBadge: Bool
        public let period: String?
        public let outcomes: [PolymarketEventCard.Outcome]

        public init(
            id: String,
            title: String,
            category: PolymarketEventCard.Category?,
            volumeText: String?,
            home: Team,
            away: Team,
            score: Score?,
            showsLiveBadge: Bool,
            period: String?,
            outcomes: [PolymarketEventCard.Outcome]
        ) {
            self.id = id
            self.title = title
            self.category = category
            self.volumeText = volumeText
            self.home = home
            self.away = away
            self.score = score
            self.showsLiveBadge = showsLiveBadge
            self.period = period
            self.outcomes = outcomes
        }
    }

    struct Team: Equatable {
        public let name: String
        public let logoURL: URL?

        public init(name: String, logoURL: URL?) {
            self.name = name
            self.logoURL = logoURL
        }
    }

    struct Score: Equatable {
        public let home: String
        public let away: String

        public init(home: String, away: String) {
            self.home = home
            self.away = away
        }
    }
}
