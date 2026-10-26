//
//  PolymarketEventChartComplementTests.swift
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

@Suite("Polymarket chart complement")
struct PolymarketEventChartComplementTests {
    @Test("A line whose history ends early is carried on as the mirror of the other one")
    func shortLineIsCarriedOnAsTheMirror() throws {
        let content = Self.content(isComplementaryPair: true)
        let long = Self.series("a", [(0, 0.6), (60, 0.62), (120, 0.55)])
        let short = Self.series("b", [(0, 0.4), (60, 0.38)])

        let result = content.complemented([long, short])
        let carried = try #require(result.last)
        let dates = carried.points.map(\.date)
        let expectedDates = [0, 60, 120].map(Self.date)

        #expect(dates == expectedDates)
        #expect(carried.points.last?.probability == Self.decimal("0.45"))
        #expect(result.first == long)
    }

    @Test("A line whose history starts late is led in by the mirror of the other one")
    func lateLineIsLedInByTheMirror() throws {
        let content = Self.content(isComplementaryPair: true)
        let early = Self.series("a", [(0, 0.7), (60, 0.65), (120, 0.6)])
        let late = Self.series("b", [(120, 0.4)])

        let led = try #require(content.complemented([early, late]).last)
        let dates = led.points.map(\.date)
        let expectedDates = [0, 60, 120].map(Self.date)

        #expect(dates == expectedDates)
        #expect(led.points.first?.probability == Self.decimal("0.3"))
    }

    @Test("A line without any history is drawn entirely as the mirror of the other one")
    func emptyLineIsDrawnAsTheMirror() throws {
        let content = Self.content(isComplementaryPair: true)
        let full = Self.series("a", [(0, 0.8), (60, 0.75)])
        let empty = Self.series("b", [])

        let mirrored = try #require(content.complemented([full, empty]).last)
        let probabilities = mirrored.points.map(\.probability)

        #expect(probabilities == [Self.decimal("0.2"), Self.decimal("0.25")])
    }

    @Test("Outcomes of different markets do not add up to a whole and are left as they are")
    func unrelatedOutcomesAreLeftAlone() {
        let content = Self.content(isComplementaryPair: false)
        let long = Self.series("a", [(0, 0.6), (60, 0.62), (120, 0.55)])
        let short = Self.series("b", [(0, 0.2)])

        #expect(content.complemented([long, short]) == [long, short])
    }

    @Test("A line too short to draw is held flat at its last price across the other lines' span")
    func aShortLineIsHeldFlatAcrossTheSpan() {
        let content = Self.content(isComplementaryPair: false)
        let long = Self.series("a", [(0, 0.6), (60, 0.62), (120, 0.55)])
        let short = Self.series("b", [(90, 0.2)])

        let filled = content.filledIn([long, short])
        let dates = filled[1].points.map(\.date)
        let probabilities = filled[1].points.map(\.probability)

        #expect(filled[0] == long)
        #expect(dates == [Self.date(0), Self.date(120)])
        #expect(probabilities == [Self.decimal("0.2"), Self.decimal("0.2")])
    }

    @Test("Nothing is invented when no line has a history to borrow a span from")
    func nothingIsFilledWithoutAnyHistory() {
        let content = Self.content(isComplementaryPair: false)
        let lines = [Self.series("a", [(0, 0.6)]), Self.series("b", [])]

        #expect(content.filledIn(lines) == lines)
    }

    @Test("A history too short to draw keeps every outcome in the legend with an empty plot")
    func aTooShortHistoryKeepsTheOutcomes() {
        let content = PolymarketEventChartContent(
            outcomes: [
                PolymarketEventChartContent.Outcome(tokenId: "a", title: "A", probability: Self.decimal("0.6"), color: .blue),
                PolymarketEventChartContent.Outcome(tokenId: "b", title: "B", probability: Self.decimal("0.3"), color: .red),
            ],
            intervals: [.allTime],
            initialInterval: .allTime,
            lifetime: Self.lifetime,
            isLive: false,
            isComplementaryPair: false
        )

        let series = content.series(from: [
            "a": [PolymarketPricePoint(date: Self.date(0), probability: Self.decimal("0.6"))],
            "b": [],
        ])

        let ids = series.map(\.id)
        let pointCounts = series.map(\.points.count)

        #expect(ids == ["a", "b"])
        #expect(pointCounts == [0, 0])
    }
}

// MARK: - Fixtures

private extension PolymarketEventChartComplementTests {
    static let start = Date(timeIntervalSince1970: 1_791_000_000)
    static let lifetime = PolymarketMarketLifetime(start: start, status: .open)

    static func decimal(_ text: String) -> Decimal {
        Decimal(string: text) ?? 0
    }

    static func date(_ offset: TimeInterval) -> Date {
        start.addingTimeInterval(offset)
    }

    static func content(isComplementaryPair: Bool) -> PolymarketEventChartContent {
        PolymarketEventChartContent(
            outcomes: [],
            intervals: [.hour],
            initialInterval: .hour,
            lifetime: lifetime,
            isLive: false,
            isComplementaryPair: isComplementaryPair
        )
    }

    static func series(_ id: String, _ points: [(TimeInterval, Double)]) -> PolymarketProbabilityChart.Series {
        PolymarketProbabilityChart.Series(
            id: id,
            title: id,
            probabilityText: "",
            color: .blue,
            points: points.map { PolymarketProbabilityChart.Point(date: date($0.0), probability: decimal(String($0.1))) }
        )
    }
}
