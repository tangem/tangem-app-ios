//
//  PolymarketMarketListLabelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemPolymarket
import TangemPolymarketUI
@testable import Tangem

@Suite("Polymarket market list label")
struct PolymarketMarketListLabelTests {
    @Test(
        "A market of a multi-market event is titled by the rule of its event",
        arguments: [
            Case(eventNegRisk: false, marketNegRisk: false, groupItemTitle: "Group", expected: "Question"),
            Case(eventNegRisk: false, marketNegRisk: false, groupItemTitle: nil, expected: "Question"),
            Case(eventNegRisk: false, marketNegRisk: false, groupItemTitle: "  ", expected: "Question"),
            Case(eventNegRisk: true, marketNegRisk: true, groupItemTitle: "Group", expected: "Group"),
            Case(eventNegRisk: true, marketNegRisk: true, groupItemTitle: nil, expected: "Question"),
            Case(eventNegRisk: true, marketNegRisk: true, groupItemTitle: "", expected: "Question"),
            Case(eventNegRisk: true, marketNegRisk: true, groupItemTitle: "  ", expected: "Question"),
            Case(eventNegRisk: true, marketNegRisk: false, groupItemTitle: "Group", expected: "Group"),
            Case(eventNegRisk: false, marketNegRisk: true, groupItemTitle: "Group", expected: "Question"),
        ]
    )
    func multiMarketEvent(_ testCase: Case) {
        let market = Self.makeMarket(question: "Question", groupItemTitle: testCase.groupItemTitle, isNegRisk: testCase.marketNegRisk)
        let event = Self.makeEvent(isNegRisk: testCase.eventNegRisk, totalMarketsCount: 2, markets: [market])

        #expect(event.listLabel(for: market) == testCase.expected)
    }

    @Test("The display mode the backend sends wins over the negRisk flag", arguments: [
        (PolymarketDisplayMode.plainMarkets, true, "Question"),
        (PolymarketDisplayMode.groupedOutcomes, false, "Group"),
    ])
    func displayModeWinsOverNegRisk(displayMode: PolymarketDisplayMode, isNegRisk: Bool, expected: String) {
        let market = Self.makeMarket(question: "Question", groupItemTitle: "Group", isNegRisk: isNegRisk)
        let event = Self.makeEvent(isNegRisk: isNegRisk, displayMode: displayMode, totalMarketsCount: 2, markets: [market])

        #expect(event.listLabel(for: market) == expected)
    }

    @Test("A market without a question falls back to its group title in an independent event")
    func emptyQuestionFallsBackToGroupTitle() {
        let market = Self.makeMarket(question: "", groupItemTitle: "Group", isNegRisk: false)
        let event = Self.makeEvent(isNegRisk: false, totalMarketsCount: 2, markets: [market])

        #expect(event.listLabel(for: market) == "Group")
    }

    @Test("A market with neither a question nor a group title has no label")
    func noTitlesGiveNoLabel() {
        let market = Self.makeMarket(question: " ", groupItemTitle: nil, isNegRisk: true)
        let event = Self.makeEvent(isNegRisk: true, totalMarketsCount: 2, markets: [market])

        #expect(event.listLabel(for: market) == nil)
    }

    @Test("A label that repeats the event title is dropped")
    func labelRepeatingEventTitleIsDropped() {
        let market = Self.makeMarket(question: "lakers vs. celtics", groupItemTitle: nil, isNegRisk: false)
        let event = Self.makeEvent(title: "Lakers vs. Celtics", isNegRisk: false, totalMarketsCount: 2, markets: [market])

        #expect(event.listLabel(for: market) == nil)
    }

    @Test("A match winner group title falls back to the question in a grouped event")
    func matchWinnerFallsBackToQuestion() {
        let market = Self.makeMarket(question: "Question", groupItemTitle: "Match Winner", isNegRisk: true)
        let event = Self.makeEvent(isNegRisk: true, totalMarketsCount: 2, markets: [market])

        #expect(event.listLabel(for: market) == "Question")
    }

    @Test(
        "A single-market event labels its market only by the group title, even when it repeats the event title",
        arguments: [
            Case(eventNegRisk: false, marketNegRisk: false, groupItemTitle: "Group", expected: "Group"),
            Case(eventNegRisk: false, marketNegRisk: false, groupItemTitle: nil, expected: nil),
            Case(eventNegRisk: true, marketNegRisk: true, groupItemTitle: "Group", expected: "Group"),
            Case(eventNegRisk: true, marketNegRisk: true, groupItemTitle: nil, expected: nil),
            Case(eventNegRisk: true, marketNegRisk: true, groupItemTitle: "Match Winner", expected: nil),
            Case(eventNegRisk: false, marketNegRisk: false, groupItemTitle: "Event", expected: "Event"),
        ]
    )
    func singleMarketEvent(_ testCase: Case) {
        let market = Self.makeMarket(question: "Question", groupItemTitle: testCase.groupItemTitle, isNegRisk: testCase.marketNegRisk)
        let event = Self.makeEvent(isNegRisk: testCase.eventNegRisk, totalMarketsCount: 1, markets: [market])

        #expect(event.listLabel(for: market) == testCase.expected)
    }

    @Test("Event details cards of an independent event show the market questions")
    func eventDetailsCardsShowQuestions() {
        let markets = [
            Self.makeMarket(id: "a", question: "Will A happen?", groupItemTitle: nil, isNegRisk: false),
            Self.makeMarket(id: "b", question: "Will B happen?", groupItemTitle: "B", isNegRisk: false),
        ]
        let event = Self.makeEvent(isNegRisk: false, totalMarketsCount: markets.count, markets: markets)

        let content = PolymarketEventDetailsContent.make(event: event, category: nil, onSelectOutcome: { _, _ in })

        let titles = content.activeMarkets.map(\.title)

        #expect(titles == ["Will A happen?", "Will B happen?"])
    }

    @Test("Feed card rows of a grouped event show the group titles")
    func feedCardRowsShowGroupTitles() {
        let markets = [
            Self.makeMarket(id: "a", question: "Will A win?", groupItemTitle: "A", isNegRisk: true),
            Self.makeMarket(id: "b", question: "Will B win?", groupItemTitle: nil, isNegRisk: true),
        ]
        let event = Self.makeEvent(isNegRisk: true, totalMarketsCount: markets.count, markets: markets)

        let card = PolymarketEventCard.Model.make(event: event, category: nil, isInActivePredicts: false, onSelectOutcome: { _, _ in })

        let titles = card.rows.map(\.title)

        #expect(titles == ["A", "Will B win?"])
    }
}

// MARK: - Fixtures

extension PolymarketMarketListLabelTests {
    struct Case: Sendable, CustomTestStringConvertible {
        let eventNegRisk: Bool
        let marketNegRisk: Bool
        let groupItemTitle: String?
        let expected: String?

        var testDescription: String {
            "event negRisk \(eventNegRisk), market negRisk \(marketNegRisk), groupItemTitle \(groupItemTitle ?? "nil")"
        }
    }
}

private extension PolymarketMarketListLabelTests {
    static func makeMarket(id: String = "market", question: String, groupItemTitle: String?, isNegRisk: Bool) -> PolymarketMarket {
        PolymarketMarket(
            id: id,
            conditionId: nil,
            title: question,
            groupItemTitle: groupItemTitle,
            imageURL: nil,
            iconURL: nil,
            status: .active,
            isNegRisk: isNegRisk,
            isAcceptingOrders: true,
            startDate: nil,
            endDate: nil,
            volume: nil,
            volume24h: nil,
            liquidity: nil,
            orderIndex: nil,
            outcomes: [
                PolymarketOutcome(assetId: "\(id)-yes", title: "Yes", probability: 0.6),
                PolymarketOutcome(assetId: "\(id)-no", title: "No", probability: 0.4),
            ]
        )
    }

    static func makeEvent(
        title: String = "Event",
        isNegRisk: Bool,
        displayMode: PolymarketDisplayMode? = nil,
        totalMarketsCount: Int,
        markets: [PolymarketMarket]
    ) -> PolymarketEvent {
        PolymarketEvent(
            id: "event",
            slug: "event",
            title: title,
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
            totalMarketsCount: totalMarketsCount,
            isNegRisk: isNegRisk,
            displayMode: displayMode ?? (isNegRisk ? .groupedOutcomes : .plainMarkets),
            markets: markets
        )
    }
}
