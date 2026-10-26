//
//  PolymarketPriceHistoryMappingTests.swift
//  TangemPolymarketTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemPolymarket

@Suite("Polymarket price history mapping")
struct PolymarketPriceHistoryMappingTests {
    @Test("An empty history maps to no points")
    func emptyHistoryHasNoPoints() throws {
        let points = try Self.map(#"{ "history": [] }"#)

        #expect(points.isEmpty)
    }

    @Test("Unix seconds become dates and the points come out in time order")
    func pointsAreDatedAndSorted() throws {
        let points = try Self.map("""
        {
          "history": [
            { "t": 1787000300, "p": 0.5 },
            { "t": 1787000100, "p": 0.25 },
            { "t": 1787000200, "p": 0.75 }
          ]
        }
        """)
        let expected = [
            Self.point(1_787_000_100, 0.25),
            Self.point(1_787_000_200, 0.75),
            Self.point(1_787_000_300, 0.5),
        ]

        #expect(points == expected)
    }

    @Test("Of several prices at one timestamp the last valid one wins")
    func lastValidPriceWinsATimestamp() throws {
        let points = try Self.map("""
        {
          "history": [
            { "t": 1787000100, "p": 0.25 },
            { "t": 1787000100, "p": 0.75 },
            { "t": 1787000100, "p": 1.5 }
          ]
        }
        """)
        let expected = [Self.point(1_787_000_100, 0.75)]

        #expect(points == expected)
    }

    @Test("Prices outside 0...1 are dropped while 0 and 1 themselves are kept")
    func outOfRangePricesAreDropped() throws {
        let points = try Self.map("""
        {
          "history": [
            { "t": 1787000100, "p": -0.25 },
            { "t": 1787000200, "p": 0 },
            { "t": 1787000300, "p": 1 },
            { "t": 1787000400, "p": 1.5 }
          ]
        }
        """)
        let expected = [
            Self.point(1_787_000_200, 0),
            Self.point(1_787_000_300, 1),
        ]

        #expect(points == expected)
    }
}

// MARK: - Helpers

private extension PolymarketPriceHistoryMappingTests {
    static func map(_ json: String) throws -> [PolymarketPricePoint] {
        let dto = try JSONDecoder().decode(PolymarketDTO.PriceHistoryResponse.self, from: Data(json.utf8))

        return PolymarketMapper().mapPriceHistory(dto)
    }

    static func point(_ timestamp: TimeInterval, _ probability: Decimal) -> PolymarketPricePoint {
        PolymarketPricePoint(date: Date(timeIntervalSince1970: timestamp), probability: probability)
    }
}
