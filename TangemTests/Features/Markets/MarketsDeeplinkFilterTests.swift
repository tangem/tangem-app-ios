//
//  MarketsDeeplinkFilterTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

/// These tests pin down the acceptance criteria for `tangem://markets?order=…&interval=…`
/// mapping: both parameters fall back independently and the default filter is
/// `order = rating, interval = 24h`.
@Suite("MarketsDeeplinkFilterFactory")
struct MarketsDeeplinkFilterTests {
    private let factory = MarketsDeeplinkFilterFactory()

    // MARK: - Valid combinations

    @Test(
        "Maps supported order values to MarketsListOrderType",
        arguments: [
            ("rating", MarketsListOrderType.rating),
            ("trending", .trending),
            ("buyers", .buyers),
            ("gainers", .gainers),
            ("losers", .losers),
        ]
    )
    func mapsSupportedOrderValues(rawValue: String, expected: MarketsListOrderType) {
        let filter = factory.make(orderRawValue: rawValue, intervalRawValue: nil)

        #expect(filter.order == expected)
        #expect(filter.interval == .day, "Missing interval must default to 24h")
    }

    @Test(
        "Maps supported interval values to MarketsPriceIntervalType",
        arguments: [
            ("24h", MarketsPriceIntervalType.day),
            ("1w", .week),
            ("30d", .month),
        ]
    )
    func mapsSupportedIntervalValues(rawValue: String, expected: MarketsPriceIntervalType) {
        let filter = factory.make(orderRawValue: nil, intervalRawValue: rawValue)

        #expect(filter.interval == expected)
        #expect(filter.order == .rating, "Missing order must default to rating")
    }

    @Test("Preserves both values when both are valid")
    func preservesBothValidValues() {
        let filter = factory.make(orderRawValue: "trending", intervalRawValue: "30d")

        #expect(filter.order == .trending)
        #expect(filter.interval == .month)
    }

    // MARK: - Defaults

    @Test("Falls back to the default filter when both params are missing")
    func defaultsWhenParamsAreMissing() {
        let filter = factory.make(orderRawValue: nil, intervalRawValue: nil)

        #expect(filter == .default)
        #expect(filter.order == .rating)
        #expect(filter.interval == .day)
    }

    @Test("Falls back to defaults when params are empty strings")
    func defaultsWhenParamsAreEmptyStrings() {
        let filter = factory.make(orderRawValue: "", intervalRawValue: "")

        #expect(filter.order == .rating)
        #expect(filter.interval == .day)
    }

    @Test("Whitespace-only order is treated as invalid (no accidental trim-to-valid)")
    func whitespaceOrderIsInvalid() {
        let filter = factory.make(orderRawValue: " ", intervalRawValue: "1w")

        // `MarketsListOrderType(rawValue: " ")` returns nil — the routing layer
        // intentionally does not trim values; the parser is responsible for the
        // canonical form (lowercased, un-encoded).
        #expect(filter.order == .rating)
        #expect(filter.interval == .week)
    }

    // MARK: - Independent fallbacks (core of AC)

    @Test("Invalid order with valid interval keeps the interval and defaults the order")
    func invalidOrderKeepsInterval() {
        let filter = factory.make(orderRawValue: "unknown_sort", intervalRawValue: "1w")

        #expect(filter.order == .rating)
        #expect(filter.interval == .week)
    }

    @Test("Valid order with invalid interval keeps the order and defaults the interval")
    func invalidIntervalKeepsOrder() {
        let filter = factory.make(orderRawValue: "gainers", intervalRawValue: "5y")

        #expect(filter.order == .gainers)
        #expect(filter.interval == .day)
    }

    @Test("Both invalid values produce the default filter")
    func bothInvalidValuesProduceDefault() {
        let filter = factory.make(orderRawValue: "bogus", intervalRawValue: "bogus")

        #expect(filter == .default)
    }

    // MARK: - Interval contract edge cases

    @Test(
        "Rejects MarketsPriceIntervalType rawValues that are not part of the deeplink contract",
        arguments: ["1m", "3m", "6m", "1y", "all_time"]
    )
    func rejectsNonContractIntervalRawValues(rawValue: String) {
        // The deeplink contract only exposes `24h / 1w / 30d`, even though the
        // `MarketsPriceIntervalType` enum itself supports additional values for
        // the internal Markets chart UI. Anything else must fall back to `.day`.
        let filter = factory.make(orderRawValue: nil, intervalRawValue: rawValue)

        #expect(filter.interval == .day)
    }

    @Test("Interval-only deeplink defaults order to rating (per AC)")
    func intervalOnlyDefaultsOrderToRating() {
        let filter = factory.make(orderRawValue: nil, intervalRawValue: "1w")

        #expect(filter.order == .rating)
        #expect(filter.interval == .week)
    }
}
