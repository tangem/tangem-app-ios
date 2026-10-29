//
//  PolymarketLiveGameCardModel+Mapping.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket
import TangemPolymarketUI

extension PolymarketLiveGameCard.Model {
    static func make(
        event: PolymarketEvent,
        liveGame: PolymarketLiveGame?,
        liveQuotesByAssetId: [String: PolymarketOutcomeQuote],
        onSelectOutcome: @escaping (PolymarketMarket, PolymarketOutcome) -> Void
    ) -> Self? {
        guard
            let game = PolymarketGameState(event: event, liveGame: liveGame),
            game.isLive || game.hasEnded,
            let moneyline = event.moneyline
        else {
            return nil
        }

        let titles = buttonTitles(of: moneyline)

        return Self(
            id: event.id,
            title: event.title,
            category: nil,
            volumeText: PolymarketEventCard.Model.volumeText(of: event),
            home: PolymarketLiveGameCard.Team(name: moneyline.home.team.name, logoURL: moneyline.home.team.logoURL),
            away: PolymarketLiveGameCard.Team(name: moneyline.away.team.name, logoURL: moneyline.away.team.logoURL),
            score: displayedScore(game.score, firstTeamSide: event.teams.count == 2 ? event.teams.first?.side : nil),
            showsLiveBadge: game.showsLiveBadge,
            period: game.period,
            outcomes: [
                outcome(moneyline.home.pick, title: titles.home, style: .affirmative, liveQuotesByAssetId, onSelectOutcome),
                moneyline.draw.map { outcome($0, title: MappingConstants.drawTitle, style: .neutral, liveQuotesByAssetId, onSelectOutcome) },
                outcome(moneyline.away.pick, title: titles.away, style: .negative, liveQuotesByAssetId, onSelectOutcome),
            ].compactMap { $0 }
        )
    }
}

// MARK: - Score

private extension PolymarketLiveGameCard.Model {
    struct OrderedScore {
        let first: Int
        let second: Int
    }

    // [REDACTED_TODO_COMMENT]
    static func displayedScore(_ score: PolymarketGameScore, firstTeamSide: PolymarketTeam.Side?) -> PolymarketLiveGameCard.Score? {
        guard let firstTeamSide, let ordered = orderedScore(score) else {
            return nil
        }

        switch firstTeamSide {
        case .home:
            return PolymarketLiveGameCard.Score(home: String(ordered.first), away: String(ordered.second))
        case .away:
            return PolymarketLiveGameCard.Score(home: String(ordered.second), away: String(ordered.first))
        }
    }

    static func orderedScore(_ score: PolymarketGameScore) -> OrderedScore? {
        switch score {
        case .esports(let maps, _):
            OrderedScore(first: maps.first, second: maps.second)
        case .points(let points):
            OrderedScore(first: points.first, second: points.second)
        case .tennis(let sets):
            wonSets(sets)
        case .missing, .unrecognized:
            nil
        }
    }

    static func wonSets(_ sets: [PolymarketGameScore.Points]) -> OrderedScore {
        let finishedSets = sets.filter(isFinishedSet)

        return OrderedScore(
            first: finishedSets.filter { $0.first > $0.second }.count,
            second: finishedSets.filter { $0.second > $0.first }.count
        )
    }

    static func isFinishedSet(_ set: PolymarketGameScore.Points) -> Bool {
        let leader = max(set.first, set.second)
        let trailer = min(set.first, set.second)
        let isWonByMargin = leader >= MappingConstants.setWinningGames && leader - trailer >= MappingConstants.setWinningMargin
        let isWonOnTiebreak = leader == MappingConstants.tiebreakSetGames && trailer == MappingConstants.setWinningGames

        return isWonByMargin || isWonOnTiebreak
    }
}

// MARK: - Buttons

private extension PolymarketLiveGameCard.Model {
    struct ButtonTitles {
        let home: String
        let away: String
    }

    static func buttonTitles(of moneyline: PolymarketMoneyline) -> ButtonTitles {
        guard
            let home = moneyline.home.team.abbreviation?.uppercased(),
            let away = moneyline.away.team.abbreviation?.uppercased()
        else {
            return ButtonTitles(home: moneyline.home.team.name, away: moneyline.away.team.name)
        }

        return ButtonTitles(home: home, away: away)
    }

    static func outcome(
        _ pick: PolymarketMoneyline.Pick,
        title: String,
        style: PolymarketOutcomeStyle,
        _ liveQuotesByAssetId: [String: PolymarketOutcomeQuote],
        _ onSelectOutcome: @escaping (PolymarketMarket, PolymarketOutcome) -> Void
    ) -> PolymarketEventCard.Outcome {
        PolymarketEventCard.Outcome(
            id: pick.outcome.assetId,
            title: title,
            priceText: PolymarketEventCard.Model.buttonPriceText(
                outcome: pick.outcome,
                liveQuote: liveQuotesByAssetId[pick.outcome.assetId],
                style: .compact
            ),
            style: style,
            onSelect: { onSelectOutcome(pick.market, pick.outcome) }
        )
    }
}

// MARK: - Constants

private extension PolymarketLiveGameCard.Model {
    enum MappingConstants {
        static let setWinningGames = 6
        static let setWinningMargin = 2
        static let tiebreakSetGames = 7

        // [REDACTED_TODO_COMMENT]
        static let drawTitle = "Draw"
    }
}
