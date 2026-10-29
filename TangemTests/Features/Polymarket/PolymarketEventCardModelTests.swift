//
//  PolymarketEventCardModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
import TangemPolymarket
import TangemPolymarketUI
@testable import Tangem

final class PolymarketEventCardModelTests: XCTestCase {
    // MARK: - Affirmative outcome

    func testAffirmativeOutcomeResolvedByOrderNotByLabel() {
        let market = makeMarket(outcomes: [
            makeOutcome(id: "over", title: "Over", probability: 0.64),
            makeOutcome(id: "under", title: "Under", probability: 0.36),
        ])
        let event = makeEvent(totalMarketsCount: 1, markets: [market])

        let model = PolymarketEventCard.Model.make(event: event, category: nil, isInActivePredicts: false, onSelectOutcome: { _, _ in })

        XCTAssertEqual(model.rows.first?.subtitle, PolymarketPriceFormatter.percentText(0.64))

        let outcomes = model.rows.first?.outcomes
        XCTAssertEqual(outcomes?.first?.style, .affirmative)
        XCTAssertEqual(outcomes?.last?.style, .negative)
    }

    func testEveryOutcomeAfterTheFirstIsNegative() {
        let market = makeMarket(outcomes: [
            makeOutcome(id: "yes", title: "Yes", probability: 0.5),
            makeOutcome(id: "draw", title: "Draw", probability: 0.3),
            makeOutcome(id: "no", title: "No", probability: 0.2),
        ])
        let event = makeEvent(totalMarketsCount: 1, markets: [market])

        let model = PolymarketEventCard.Model.make(event: event, category: nil, isInActivePredicts: false, onSelectOutcome: { _, _ in })

        XCTAssertEqual(model.rows.first?.outcomes.map(\.style), [.affirmative, .negative, .negative])
    }

    // MARK: - Team abbreviations

    func testTeamOutcomesShowTheTeamAbbreviation() {
        let market = makeMarket(outcomes: [
            makeOutcome(id: "lions", title: "Lions", probability: 0.45),
            makeOutcome(id: "bills", title: "Buffalo Bills", probability: 0.55),
        ])
        let event = makeEvent(totalMarketsCount: 1, markets: [market], teams: [
            PolymarketTeam(name: "Detroit Lions", abbreviation: "det", alias: "Lions", logoURL: nil, side: .away),
            PolymarketTeam(name: "Buffalo Bills", abbreviation: "buf", alias: "Bills", logoURL: nil, side: .home),
        ])

        let model = PolymarketEventCard.Model.make(event: event, category: nil, isInActivePredicts: false, onSelectOutcome: { _, _ in })

        XCTAssertEqual(model.rows.first?.outcomes.map(\.title), ["DET", "BUF"])
    }

    func testARowKeepsFullNamesWhenOneTeamHasNoAbbreviation() {
        let market = makeMarket(outcomes: [
            makeOutcome(id: "away", title: "Away player", probability: 0.4),
            makeOutcome(id: "home", title: "Home player", probability: 0.6),
        ])
        let event = makeEvent(totalMarketsCount: 1, markets: [market], teams: [
            PolymarketTeam(name: "Away player", abbreviation: "awy", alias: nil, logoURL: nil, side: .away),
            PolymarketTeam(name: "Home player", abbreviation: nil, alias: nil, logoURL: nil, side: .home),
        ])

        let model = PolymarketEventCard.Model.make(event: event, category: nil, isInActivePredicts: false, onSelectOutcome: { _, _ in })

        XCTAssertEqual(model.rows.first?.outcomes.map(\.title), ["Away player", "Home player"])
    }

    func testOutcomesThatAreNotTeamsKeepTheirLabel() {
        let market = makeMarket(outcomes: [
            makeOutcome(id: "yes", title: "Yes", probability: 0.5),
            makeOutcome(id: "draw", title: "Draw", probability: 0.3),
            makeOutcome(id: "jazz", title: "Jazz", probability: 0.2),
        ])
        let event = makeEvent(totalMarketsCount: 1, markets: [market], teams: [
            PolymarketTeam(name: "Utah Jazz", abbreviation: nil, alias: "Jazz", logoURL: nil, side: .home),
        ])

        let model = PolymarketEventCard.Model.make(event: event, category: nil, isInActivePredicts: false, onSelectOutcome: { _, _ in })

        XCTAssertEqual(model.rows.first?.outcomes.map(\.title), ["Yes", "Draw", "Jazz"])
    }

    // MARK: - Row cap and chip

    func testRowsCappedAndChipCountedFromRenderedRows() {
        let markets = (0 ..< 6).map { makeMarket(id: "m\($0)", outcomes: [makeOutcome(id: "y\($0)", title: "Yes", probability: 0.5)]) }
        let event = makeEvent(totalMarketsCount: 6, markets: markets)

        let model = PolymarketEventCard.Model.make(event: event, category: nil, isInActivePredicts: false, onSelectOutcome: { _, _ in })

        XCTAssertEqual(model.rows.count, 2)
        XCTAssertEqual(model.additionalOutcomesCount, 4)
    }

    func testThreeWayMatchShowsEveryMoneylineRow() {
        let markets = ["home", "draw", "away"].map { makeMarket(id: $0, outcomes: [makeOutcome(id: "y-\($0)", title: "Yes", probability: 0.3)]) }
        let event = makeEvent(totalMarketsCount: 3, markets: markets, teams: makeMatchTeams())

        let model = PolymarketEventCard.Model.make(event: event, category: nil, isInActivePredicts: false, onSelectOutcome: { _, _ in })

        XCTAssertEqual(model.rows.map(\.id), ["home", "draw", "away"])
        XCTAssertEqual(model.additionalOutcomesCount, 0)
        XCTAssertEqual(PolymarketEventCard.Model.displayedMarkets(of: event).count, 3)
    }

    func testThreeWayMatchRowsGoHomeDrawAwayWhateverTheBackendOrder() {
        let markets = ["Draw (Arsenal vs. Chelsea)", "Chelsea", "Arsenal"].map { title in
            makeMarket(
                id: title,
                outcomes: [
                    makeOutcome(id: "\(title)-yes", title: "Yes", probability: 0.3),
                    makeOutcome(id: "\(title)-no", title: "No", probability: 0.7),
                ]
            )
        }
        let event = makeEvent(totalMarketsCount: 3, markets: markets, teams: makeMatchTeams())

        let model = PolymarketEventCard.Model.make(event: event, category: nil, isInActivePredicts: false, onSelectOutcome: { _, _ in })

        XCTAssertEqual(model.rows.map(\.id), ["Arsenal", "Draw (Arsenal vs. Chelsea)", "Chelsea"])
        XCTAssertEqual(model.additionalOutcomesCount, 0)
    }

    func testThreeMarketEventWithoutTeamsKeepsTheChip() {
        let markets = (0 ..< 3).map { makeMarket(id: "m\($0)", outcomes: [makeOutcome(id: "y\($0)", title: "Yes", probability: 0.5)]) }
        let event = makeEvent(totalMarketsCount: 3, markets: markets)

        let model = PolymarketEventCard.Model.make(event: event, category: nil, isInActivePredicts: false, onSelectOutcome: { _, _ in })

        XCTAssertEqual(model.rows.count, 2)
        XCTAssertEqual(model.additionalOutcomesCount, 1)
    }

    func testMatchWithMoreThanThreeMarketsKeepsTheChip() {
        let markets = (0 ..< 5).map { makeMarket(id: "m\($0)", outcomes: [makeOutcome(id: "y\($0)", title: "Yes", probability: 0.5)]) }
        let event = makeEvent(totalMarketsCount: 5, markets: markets, teams: makeMatchTeams())

        let model = PolymarketEventCard.Model.make(event: event, category: nil, isInActivePredicts: false, onSelectOutcome: { _, _ in })

        XCTAssertEqual(model.rows.count, 2)
        XCTAssertEqual(model.additionalOutcomesCount, 3)
    }

    func testPartialMarketListStaysMultiMarket() {
        let event = makeEvent(totalMarketsCount: 6, markets: [makeMarket(outcomes: [makeOutcome(id: "y", title: "Yes", probability: 0.5)])])

        let model = PolymarketEventCard.Model.make(event: event, category: nil, isInActivePredicts: false, onSelectOutcome: { _, _ in })

        XCTAssertEqual(model.variant, .multiMarket)
        XCTAssertEqual(model.rows.count, 1)
        XCTAssertEqual(model.additionalOutcomesCount, 5)
    }
}

// MARK: - Stubs

private extension PolymarketEventCardModelTests {
    func makeOutcome(id: String, title: String, probability: Decimal) -> PolymarketOutcome {
        PolymarketOutcome(assetId: id, title: title, probability: probability)
    }

    func makeMarket(id: String = "market", outcomes: [PolymarketOutcome]) -> PolymarketMarket {
        PolymarketMarket(
            id: id,
            conditionId: nil,
            title: id,
            groupItemTitle: id,
            imageURL: nil,
            iconURL: nil,
            status: .active,
            isNegRisk: false,
            isAcceptingOrders: true,
            startDate: nil,
            endDate: nil,
            volume: 1_000_000,
            volume24h: nil,
            liquidity: nil,
            orderIndex: 0,
            outcomes: outcomes
        )
    }

    func makeMatchTeams() -> [PolymarketTeam] {
        [
            PolymarketTeam(name: "Arsenal", abbreviation: "ars", alias: nil, logoURL: nil, side: .home),
            PolymarketTeam(name: "Chelsea", abbreviation: "che", alias: nil, logoURL: nil, side: .away),
        ]
    }

    func makeEvent(totalMarketsCount: Int, markets: [PolymarketMarket], teams: [PolymarketTeam] = []) -> PolymarketEvent {
        PolymarketEvent(
            id: "event",
            slug: "slug",
            title: "Title",
            description: nil,
            rulesURL: nil,
            imageURL: nil,
            iconURL: nil,
            status: .active,
            isLive: false,
            startDate: nil,
            endDate: nil,
            volume: 1_000_000,
            volume24h: nil,
            liquidity: nil,
            totalMarketsCount: totalMarketsCount,
            isNegRisk: false,
            displayMode: .groupedOutcomes,
            markets: markets,
            teams: teams
        )
    }
}
