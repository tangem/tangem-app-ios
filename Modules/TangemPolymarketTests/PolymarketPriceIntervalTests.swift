//
//  PolymarketPriceIntervalTests.swift
//  TangemPolymarketTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemPolymarket

@Suite("Polymarket price interval")
struct PolymarketPriceIntervalTests {
    @Test("Every interval goes on the wire under the name the endpoint knows it by")
    func rawValuesMatchTheEndpointQuery() {
        #expect(PolymarketPriceInterval.allCases.map(\.rawValue) == ["1h", "6h", "1d", "1w", "1m", "max"])
    }

    @Test("The windows on offer follow the market's age the way Polymarket picks them", arguments: [
        AgeCase(age: 0, intervals: [.hour, .sixHours, .allTime]),
        AgeCase(age: Constants.day - Constants.minute, intervals: [.hour, .sixHours, .allTime]),
        AgeCase(age: Constants.day, intervals: [.hour, .sixHours, .day, .allTime]),
        AgeCase(age: Constants.day * 7 - Constants.minute, intervals: [.hour, .sixHours, .day, .allTime]),
        AgeCase(age: Constants.day * 7, intervals: [.hour, .sixHours, .day, .week, .allTime]),
        AgeCase(age: Constants.day * 30 - Constants.minute, intervals: [.hour, .sixHours, .day, .week, .allTime]),
        AgeCase(age: Constants.day * 30, intervals: [.hour, .day, .week, .month, .allTime]),
        AgeCase(age: Constants.day * 400, intervals: [.hour, .day, .week, .month, .allTime]),
    ])
    func windowsFollowTheMarketAge(ageCase: AgeCase) {
        #expect(PolymarketPriceInterval.available(marketAge: ageCase.age, isClosed: false) == ageCase.intervals)
    }

    @Test("A market of unknown age is treated as two months old")
    func unknownAgeIsTwoMonths() {
        #expect(PolymarketPriceInterval.assumedAgeWhenStartUnknown == Constants.day * 60)
        #expect(
            PolymarketPriceInterval.available(marketAge: PolymarketPriceInterval.assumedAgeWhenStartUnknown, isClosed: false)
                == [.hour, .day, .week, .month, .allTime]
        )
    }

    @Test("A closed market is charted only over its whole life", arguments: [0, Constants.day * 3, Constants.day * 400])
    func aClosedMarketOffersOnlyAllTime(age: TimeInterval) {
        #expect(PolymarketPriceInterval.available(marketAge: age, isClosed: true) == [.allTime])
    }
}

// MARK: - History query

@Suite("Polymarket price history query")
struct PolymarketPriceHistoryQueryTests {
    @Test("MAX charts a market from its start on a grid sized to its life, the way Polymarket does", arguments: [
        SpanCase(span: 0, fidelityMinutes: 1),
        SpanCase(span: Constants.hour * 6 - Constants.minute, fidelityMinutes: 1),
        SpanCase(span: Constants.hour * 6, fidelityMinutes: 5),
        SpanCase(span: Constants.hour * 7, fidelityMinutes: 5),
        SpanCase(span: Constants.day, fidelityMinutes: 15),
        SpanCase(span: Constants.day * 3.5, fidelityMinutes: 30),
        SpanCase(span: Constants.day * 7, fidelityMinutes: 60),
        SpanCase(span: Constants.day * 15, fidelityMinutes: 180),
        SpanCase(span: Constants.day * 30, fidelityMinutes: 720),
        SpanCase(span: Constants.day * 400, fidelityMinutes: 720),
    ])
    func allTimeFollowsTheMarketSpan(spanCase: SpanCase) {
        let start = Self.now.addingTimeInterval(-spanCase.span)
        let lifetime = PolymarketMarketLifetime(start: start, status: .open)

        #expect(
            PolymarketPriceInterval.allTime.historyQuery(lifetime: lifetime, now: Self.now)
                == .range(start: start, end: nil, fidelityMinutes: spanCase.fidelityMinutes)
        )
    }

    @Test("A short market closed long ago is charted between its start and its close on a grid sized to that span")
    func aClosedShortMarketIsBoundedByItsClose() {
        let start = Self.now.addingTimeInterval(-Constants.day * 60)
        let closedDate = start.addingTimeInterval(Constants.day * 6 + Constants.hour * 7)
        let lifetime = PolymarketMarketLifetime(
            start: start,
            status: .closed(closedDate: closedDate, scheduledEndDate: closedDate.addingTimeInterval(Constants.day * 7))
        )

        #expect(
            PolymarketPriceInterval.allTime.historyQuery(lifetime: lifetime, now: Self.now)
                == .range(start: start, end: closedDate, fidelityMinutes: 30)
        )
    }

    @Test("A closed market that lived longer than a bounded range allows is asked from its start only")
    func aLongClosedMarketIsNotBounded() {
        let start = Self.now.addingTimeInterval(-Constants.day * 250)
        let closedDate = start.addingTimeInterval(Constants.day * 20)
        let lifetime = PolymarketMarketLifetime(start: start, status: .closed(closedDate: closedDate, scheduledEndDate: nil))

        #expect(
            PolymarketPriceInterval.allTime.historyQuery(lifetime: lifetime, now: Self.now)
                == .range(start: start, end: nil, fidelityMinutes: 180)
        )
    }

    @Test("A closed market with no close time sizes its grid to the scheduled end and leaves the end open")
    func aClosedMarketWithoutCloseTimeUsesTheScheduledEnd() {
        let start = Self.now.addingTimeInterval(-Constants.day * 60)
        let lifetime = PolymarketMarketLifetime(
            start: start,
            status: .closed(closedDate: nil, scheduledEndDate: start.addingTimeInterval(Constants.day * 2))
        )

        #expect(
            PolymarketPriceInterval.allTime.historyQuery(lifetime: lifetime, now: Self.now)
                == .range(start: start, end: nil, fidelityMinutes: 15)
        )
    }

    @Test("A close time ahead of now never stretches the grid past now")
    func aFutureEndIsCappedAtNow() {
        let start = Self.now.addingTimeInterval(-Constants.hour * 2)
        let lifetime = PolymarketMarketLifetime(
            start: start,
            status: .closed(closedDate: nil, scheduledEndDate: Self.now.addingTimeInterval(Constants.day * 30))
        )

        #expect(
            PolymarketPriceInterval.allTime.historyQuery(lifetime: lifetime, now: Self.now)
                == .range(start: start, end: nil, fidelityMinutes: 1)
        )
    }

    @Test("A market with no known start keeps the chosen interval on Polymarket's default grid", arguments: [
        (PolymarketPriceInterval.hour, 10),
        (.sixHours, 10),
        (.day, 10),
        (.week, 10),
        (.month, 10),
        (.allTime, 720),
    ])
    func anUnknownStartKeepsTheInterval(interval: PolymarketPriceInterval, fidelityMinutes: Int) {
        let lifetime = PolymarketMarketLifetime(start: nil, status: .open)

        #expect(interval.historyQuery(lifetime: lifetime, now: Self.now) == .interval(interval, fidelityMinutes: fidelityMinutes))
    }

    @Test("A fixed window asks for Polymarket's fixed grid, finer for a younger market where Polymarket does", arguments: [
        WindowCase(interval: .hour, age: Constants.day * 400, expected: .hour, fidelityMinutes: 1),
        WindowCase(interval: .sixHours, age: Constants.day * 3, expected: .sixHours, fidelityMinutes: 1),
        WindowCase(interval: .day, age: Constants.day * 400, expected: .day, fidelityMinutes: 5),
        WindowCase(interval: .week, age: Constants.day * 3.5 - Constants.minute, expected: .week, fidelityMinutes: 15),
        WindowCase(interval: .week, age: Constants.day * 3.5, expected: .week, fidelityMinutes: 30),
        WindowCase(interval: .week, age: Constants.day * 400, expected: .week, fidelityMinutes: 30),
        WindowCase(interval: .month, age: Constants.day * 15 - Constants.minute, expected: .month, fidelityMinutes: 60),
        WindowCase(interval: .month, age: Constants.day * 15, expected: .month, fidelityMinutes: 180),
        WindowCase(interval: .month, age: Constants.day * 400, expected: .month, fidelityMinutes: 180),
    ])
    func aWindowUsesPolymarketsGrid(windowCase: WindowCase) {
        let lifetime = PolymarketMarketLifetime(start: Self.now.addingTimeInterval(-windowCase.age), status: .open)

        #expect(
            windowCase.interval.historyQuery(lifetime: lifetime, now: Self.now)
                == .interval(windowCase.expected, fidelityMinutes: windowCase.fidelityMinutes)
        )
    }

    @Test("A window longer than the market's life narrows to the shortest one covering it, as Polymarket does", arguments: [
        WindowCase(interval: .sixHours, age: Constants.minute * 30, expected: .hour, fidelityMinutes: 1),
        WindowCase(interval: .day, age: Constants.hour * 3, expected: .sixHours, fidelityMinutes: 1),
        WindowCase(interval: .week, age: Constants.hour * 12, expected: .day, fidelityMinutes: 5),
        WindowCase(interval: .month, age: Constants.day * 2, expected: .week, fidelityMinutes: 15),
    ])
    func aWindowNarrowsToTheMarketsLife(windowCase: WindowCase) {
        let lifetime = PolymarketMarketLifetime(start: Self.now.addingTimeInterval(-windowCase.age), status: .open)

        #expect(
            windowCase.interval.historyQuery(lifetime: lifetime, now: Self.now)
                == .interval(windowCase.expected, fidelityMinutes: windowCase.fidelityMinutes)
        )
    }

    @Test("A market's age runs from its start, and an unknown start reads as the default age")
    func lifetimeAge() {
        let known = PolymarketMarketLifetime(start: Self.now.addingTimeInterval(-Constants.day * 3), status: .open)
        let unknown = PolymarketMarketLifetime(start: nil, status: .open)

        #expect(known.age(at: Self.now) == Constants.day * 3)
        #expect(unknown.age(at: Self.now) == PolymarketPriceInterval.assumedAgeWhenStartUnknown)
    }
}

// MARK: - Fixtures

private extension PolymarketPriceHistoryQueryTests {
    static let now = Date(timeIntervalSince1970: 1_792_668_524)

    typealias Constants = PolymarketPriceIntervalTests.Constants
}

extension PolymarketPriceHistoryQueryTests {
    struct SpanCase: Sendable, CustomTestStringConvertible {
        let span: TimeInterval
        let fidelityMinutes: Int

        var testDescription: String { "\(span / 3600)h" }
    }
}

extension PolymarketPriceHistoryQueryTests {
    struct WindowCase: Sendable, CustomTestStringConvertible {
        let interval: PolymarketPriceInterval
        let age: TimeInterval
        let expected: PolymarketPriceInterval
        let fidelityMinutes: Int

        var testDescription: String { "\(interval.rawValue) at \(age / 3600)h" }
    }
}

// MARK: - Test cases

extension PolymarketPriceIntervalTests {
    struct AgeCase: Sendable, CustomTestStringConvertible {
        let age: TimeInterval
        let intervals: [PolymarketPriceInterval]

        var testDescription: String { "\(age / Constants.hour)h" }
    }
}

// MARK: - Constants

private extension PolymarketPriceIntervalTests {
    enum Constants {
        static let minute: TimeInterval = 60
        static let hour: TimeInterval = 60 * 60
        static let day: TimeInterval = 24 * 60 * 60
    }
}
