//
//  PolymarketMoneylineTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemPolymarket
@testable import Tangem

@Suite("Polymarket moneyline")
struct PolymarketMoneylineTests {
    private typealias Fixtures = PolymarketLiveGamesFixtures

    @Test("An NBA match whose guest comes first still buys the home team with the home button")
    func singleMarketPicksBySideNotByOrder() throws {
        let moneyline = try #require(Fixtures.basketball().moneyline)

        #expect(moneyline.home.team.name == "76ers")
        #expect(moneyline.home.pick.outcome.assetId == "1197295-phi")
        #expect(moneyline.away.pick.outcome.assetId == "1197295-cle")
        #expect(moneyline.draw == nil)
    }

    @Test("A soccer match buys the Yes of its own market for home, draw and away, whatever the market order", arguments: [false, true])
    func marketPerOutcomePicksYesOfEachMarket(drawFirst: Bool) throws {
        let moneyline = try #require(Fixtures.soccer(drawFirst: drawFirst).moneyline)

        #expect(moneyline.home.pick.outcome.assetId == "1201001-ars-yes")
        #expect(moneyline.draw?.outcome.assetId == "1201001-draw-yes")
        #expect(moneyline.away.pick.outcome.assetId == "1201001-che-yes")
    }

    @Test("Markets that are not the match result give no moneyline", arguments: NotAMoneyline.allCases)
    func notAMoneylineGivesNothing(_ shape: NotAMoneyline) {
        #expect(shape.event.moneyline == nil)
    }

    enum NotAMoneyline: CaseIterable, CustomTestStringConvertible {
        case halftimeResult
        case firstTeamToScore
        case noIsTheFirstOutcome
        case marketsLeftOut
        case outcomesNamedOtherwise

        var event: PolymarketEvent {
            switch self {
            case .halftimeResult:
                Fixtures.soccer(drawTitle: "Draw")
            case .firstTeamToScore:
                Fixtures.soccer(drawTitle: "Neither")
            case .noIsTheFirstOutcome:
                Fixtures.event(
                    id: "e",
                    title: "Arsenal FC vs. Chelsea FC",
                    isLive: true,
                    markets: [
                        Fixtures.yesNoMarket(id: "ars", groupItemTitle: "Arsenal FC", yesFirst: false),
                        Fixtures.yesNoMarket(id: "draw", groupItemTitle: "Draw (Arsenal FC vs. Chelsea FC)"),
                        Fixtures.yesNoMarket(id: "che", groupItemTitle: "Chelsea FC"),
                    ],
                    teams: Fixtures.soccer().teams,
                    game: nil
                )
            case .marketsLeftOut:
                Fixtures.soccer(totalMarketsCount: 4)
            case .outcomesNamedOtherwise:
                Fixtures.event(
                    id: "e",
                    title: "Cavaliers vs. 76ers",
                    isLive: true,
                    markets: [
                        Fixtures.market(
                            id: "m",
                            groupItemTitle: nil,
                            outcomes: [
                                PolymarketOutcome(assetId: "over", title: "Over", probability: nil),
                                PolymarketOutcome(assetId: "under", title: "Under", probability: nil),
                            ]
                        ),
                    ],
                    teams: Fixtures.basketball().teams,
                    game: nil
                )
            }
        }

        var testDescription: String {
            switch self {
            case .halftimeResult: "a halftime result market titled Draw"
            case .firstTeamToScore: "a first team to score market titled Neither"
            case .noIsTheFirstOutcome: "a team market whose first outcome is No"
            case .marketsLeftOut: "markets the page left out"
            case .outcomesNamedOtherwise: "outcomes that are not the teams"
            }
        }
    }
}
