//
//  PolymarketEventChartColorTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Testing
import TangemPolymarket
import TangemPolymarketUI
@testable import Tangem

@Suite("Polymarket event chart colors")
struct PolymarketEventChartColorTests {
    @Test("A two-sided market keeps each line in its outcome's button color when the second outcome leads")
    func linesFollowTheOutcomeOrderNotTheRank() throws {
        let content = try #require(Self.content(firstProbability: 0.36, secondProbability: 0.68))
        let tokenIDs = content.outcomes.map(\.tokenId)

        #expect(tokenIDs == ["second", "first"])
        #expect(content.outcomes[0].color == PolymarketOutcomeStyle(outcomeIndex: 1).chartColor)
        #expect(content.outcomes[1].color == PolymarketOutcomeStyle(outcomeIndex: 0).chartColor)
    }

    @Test("A two-sided market led by its first outcome keeps the same colors")
    func colorsHoldWhenTheFirstOutcomeLeads() throws {
        let content = try #require(Self.content(firstProbability: 0.57, secondProbability: 0.44))
        let tokenIDs = content.outcomes.map(\.tokenId)

        #expect(tokenIDs == ["first", "second"])
        #expect(content.outcomes[0].color == PolymarketOutcomeStyle(outcomeIndex: 0).chartColor)
        #expect(content.outcomes[1].color == PolymarketOutcomeStyle(outcomeIndex: 1).chartColor)
    }

    @Test("A match with a draw paints the teams like their buttons and the draw neutral")
    func drawIsNeutral() throws {
        let markets = [
            Self.market(id: "home", groupItemTitle: "Team A", probability: 0.36),
            Self.market(id: "draw", groupItemTitle: "Draw (Team A vs. Team B)", probability: 0.32),
            Self.market(id: "away", groupItemTitle: "Team B", probability: 0.34),
        ]
        let content = try #require(Self.content(markets: markets, teams: Self.teams))
        let colors = Dictionary(uniqueKeysWithValues: content.outcomes.map { ($0.tokenId, $0.color) })

        #expect(colors["home-yes"] == PolymarketOutcomeStyle(outcomeIndex: 0).chartColor)
        #expect(colors["away-yes"] == PolymarketOutcomeStyle(outcomeIndex: 1).chartColor)
        #expect(colors["draw-yes"] == .draw)
    }

    @Test("A match that also has spreads and totals still paints the draw neutral among its moneyline markets")
    func drawIsNeutralNextToOtherMarkets() throws {
        let markets = [
            Self.market(id: "home", groupItemTitle: "Team A", probability: 0.36, conditionId: "home-condition"),
            Self.market(id: "spread", groupItemTitle: "Spread -1.5", probability: 0.4, conditionId: "spread-condition"),
            Self.market(id: "draw", groupItemTitle: "Draw (Team A vs. Team B)", probability: 0.32, conditionId: "draw-condition"),
            Self.market(id: "total", groupItemTitle: "O/U 2.5", probability: 0.5, conditionId: "total-condition"),
            Self.market(id: "away", groupItemTitle: "Team B", probability: 0.34, conditionId: "away-condition"),
        ]
        let sports = PolymarketEventSports(
            isSports: true,
            moneylineConditionIds: ["home-condition", "draw-condition", "away-condition"]
        )
        let content = try #require(Self.content(markets: markets, teams: Self.teams, sports: sports))
        let colors = Dictionary(uniqueKeysWithValues: content.outcomes.map { ($0.tokenId, $0.color) })

        #expect(colors.keys.sorted() == ["away-yes", "draw-yes", "home-yes"])
        #expect(colors["home-yes"] == PolymarketOutcomeStyle(outcomeIndex: 0).chartColor)
        #expect(colors["away-yes"] == PolymarketOutcomeStyle(outcomeIndex: 1).chartColor)
        #expect(colors["draw-yes"] == .draw)
    }

    @Test("Moneyline markets are found whatever the letter case of their condition ids")
    func moneylineConditionIdsIgnoreCase() throws {
        let markets = [
            Self.market(id: "home", groupItemTitle: "Team A", probability: 0.36, conditionId: "0xABC1"),
            Self.market(id: "spread", groupItemTitle: "Spread -1.5", probability: 0.4, conditionId: "0xABC2"),
            Self.market(id: "away", groupItemTitle: "Team B", probability: 0.34, conditionId: "0xABC3"),
        ]
        let sports = PolymarketEventSports(isSports: true, moneylineConditionIds: ["0xabc1", "0xabc3"])
        let content = try #require(Self.content(markets: markets, teams: Self.teams, sports: sports))

        #expect(Set(content.outcomes.map(\.tokenId)) == ["home-yes", "away-yes"])
    }

    @Test("Four outcomes take the palette in order of their chances")
    func fourOutcomesFollowThePalette() throws {
        let markets = [
            Self.market(id: "a", groupItemTitle: "A", probability: 0.22),
            Self.market(id: "b", groupItemTitle: "B", probability: 0.28),
            Self.market(id: "c", groupItemTitle: "C", probability: 0.25),
            Self.market(id: "d", groupItemTitle: "D", probability: 0.24),
        ]
        let content = try #require(Self.content(markets: markets))
        let tokenIDs = content.outcomes.map(\.tokenId)
        let colors = content.outcomes.map(\.color)
        let palette = (0 ..< 4).map(PolymarketProbabilityChart.color(forSeriesAt:))

        #expect(tokenIDs == ["b-yes", "c-yes", "d-yes", "a-yes"])
        #expect(colors == palette)
    }
}

// MARK: - Fixtures

private extension PolymarketEventChartColorTests {
    static let teams = [
        PolymarketTeam(name: "Team A", abbreviation: "TA", alias: nil, logoURL: nil, side: .home),
        PolymarketTeam(name: "Team B", abbreviation: "TB", alias: nil, logoURL: nil, side: .away),
    ]

    static func market(id: String, groupItemTitle: String, probability: Decimal, conditionId: String? = nil) -> PolymarketMarket {
        PolymarketMarket(
            id: id,
            conditionId: conditionId,
            title: groupItemTitle,
            groupItemTitle: groupItemTitle,
            imageURL: nil,
            iconURL: nil,
            status: .active,
            isNegRisk: false,
            isAcceptingOrders: true,
            startDate: Date(timeIntervalSince1970: 1_787_000_000),
            endDate: nil,
            volume: nil,
            volume24h: nil,
            liquidity: nil,
            orderIndex: nil,
            outcomes: [
                PolymarketOutcome(assetId: "\(id)-yes", title: "Yes", probability: probability),
                PolymarketOutcome(assetId: "\(id)-no", title: "No", probability: 1 - probability),
            ]
        )
    }

    static func content(
        markets: [PolymarketMarket],
        teams: [PolymarketTeam] = [],
        sports: PolymarketEventSports? = nil
    ) -> PolymarketEventChartContent? {
        PolymarketEventChartContent.make(
            event: PolymarketEvent(
                id: "event",
                slug: "event",
                title: "Match",
                description: nil,
                rulesURL: nil,
                imageURL: nil,
                iconURL: nil,
                status: .active,
                isLive: false,
                startDate: nil,
                endDate: nil,
                volume: nil,
                volume24h: nil,
                liquidity: nil,
                totalMarketsCount: markets.count,
                isNegRisk: false,
                displayMode: .plainMarkets,
                markets: markets,
                teams: teams
            ),
            marketIDs: markets.map(\.id),
            sports: sports,
            now: Date(timeIntervalSince1970: 1_787_100_000)
        )
    }

    static func content(firstProbability: Decimal, secondProbability: Decimal) -> PolymarketEventChartContent? {
        let market = PolymarketMarket(
            id: "market",
            conditionId: nil,
            title: "Team A vs Team B",
            groupItemTitle: nil,
            imageURL: nil,
            iconURL: nil,
            status: .active,
            isNegRisk: false,
            isAcceptingOrders: true,
            startDate: Date(timeIntervalSince1970: 1_787_000_000),
            endDate: nil,
            volume: nil,
            volume24h: nil,
            liquidity: nil,
            orderIndex: nil,
            outcomes: [
                PolymarketOutcome(assetId: "first", title: "Team A", probability: firstProbability),
                PolymarketOutcome(assetId: "second", title: "Team B", probability: secondProbability),
            ]
        )

        let event = PolymarketEvent(
            id: "event",
            slug: "event",
            title: "Team A vs Team B",
            description: nil,
            rulesURL: nil,
            imageURL: nil,
            iconURL: nil,
            status: .active,
            isLive: false,
            startDate: nil,
            endDate: nil,
            volume: nil,
            volume24h: nil,
            liquidity: nil,
            totalMarketsCount: 1,
            isNegRisk: false,
            displayMode: .plainMarkets,
            markets: [market]
        )

        return PolymarketEventChartContent.make(
            event: event,
            marketIDs: [market.id],
            sports: nil,
            now: Date(timeIntervalSince1970: 1_787_100_000)
        )
    }
}
