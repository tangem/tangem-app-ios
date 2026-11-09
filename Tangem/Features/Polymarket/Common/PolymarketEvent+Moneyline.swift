//
//  PolymarketEvent+Moneyline.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket

extension PolymarketEvent {
    // [REDACTED_TODO_COMMENT]
    var moneyline: PolymarketMoneyline? {
        guard !hasMoreMarkets else {
            return nil
        }

        return moneyline(in: markets)
    }

    func moneyline(in markets: [PolymarketMarket]) -> PolymarketMoneyline? {
        guard
            let home = teams.first(where: { $0.side == .home }),
            let away = teams.first(where: { $0.side == .away })
        else {
            return nil
        }

        return singleMarketMoneyline(in: markets, home: home, away: away)
            ?? marketPerOutcomeMoneyline(in: markets, home: home, away: away)
    }
}

// MARK: - PolymarketMoneyline

struct PolymarketMoneyline {
    let home: TeamPick
    let draw: Pick?
    let away: TeamPick

    var picks: [Pick] {
        [home.pick] + (draw.map { [$0] } ?? []) + [away.pick]
    }
}

extension PolymarketMoneyline {
    struct Pick {
        let market: PolymarketMarket
        let outcome: PolymarketOutcome
    }

    struct TeamPick {
        let team: PolymarketTeam
        let pick: Pick
    }
}

// MARK: - Private

private extension PolymarketEvent {
    func singleMarketMoneyline(in markets: [PolymarketMarket], home: PolymarketTeam, away: PolymarketTeam) -> PolymarketMoneyline? {
        guard
            markets.count == 1,
            let market = markets.first,
            market.outcomes.count == 2,
            let homeOutcome = market.outcomes.first(where: { team(named: $0.title) == home }),
            let awayOutcome = market.outcomes.first(where: { team(named: $0.title) == away })
        else {
            return nil
        }

        return PolymarketMoneyline(
            home: .init(team: home, pick: .init(market: market, outcome: homeOutcome)),
            draw: nil,
            away: .init(team: away, pick: .init(market: market, outcome: awayOutcome))
        )
    }

    func marketPerOutcomeMoneyline(in markets: [PolymarketMarket], home: PolymarketTeam, away: PolymarketTeam) -> PolymarketMoneyline? {
        guard
            markets.count == Constants.marketPerOutcomeCount,
            let homePick = yesPick(in: markets.first { $0.groupItemTitle.flatMap(team(named:)) == home }),
            let awayPick = yesPick(in: markets.first { $0.groupItemTitle.flatMap(team(named:)) == away }),
            homePick.market.id != awayPick.market.id,
            let drawMarket = markets.first(where: { $0.id != homePick.market.id && $0.id != awayPick.market.id }),
            drawMarket.groupItemTitle?.hasPrefix(Constants.matchDrawTitlePrefix) == true,
            let drawPick = yesPick(in: drawMarket)
        else {
            return nil
        }

        return PolymarketMoneyline(
            home: .init(team: home, pick: homePick),
            draw: drawPick,
            away: .init(team: away, pick: awayPick)
        )
    }

    func yesPick(in market: PolymarketMarket?) -> PolymarketMoneyline.Pick? {
        guard
            let market,
            market.outcomes.count == 2,
            let yes = market.outcomes.first,
            yes.title.trimmingCharacters(in: .whitespacesAndNewlines).caseInsensitiveCompare(Constants.yesTitle) == .orderedSame
        else {
            return nil
        }

        return PolymarketMoneyline.Pick(market: market, outcome: yes)
    }
}

// MARK: - Constants

private extension PolymarketEvent {
    enum Constants {
        static let marketPerOutcomeCount = 3
        static let matchDrawTitlePrefix = "Draw ("
        static let yesTitle = "Yes"
    }
}
