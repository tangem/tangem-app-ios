//
//  PolymarketPositionsMappingTests.swift
//  TangemPolymarketTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemPolymarket

@Suite("Polymarket positions mapping", .timeLimit(.minutes(1)))
struct PolymarketPositionsMappingTests {
    private let mapper = PolymarketMapper()
    private let decoder = JSONDecoder()

    @Test("A page decodes into the domain model with its money read as decimals")
    func pageMapping() throws {
        let page = try mapPage(Self.pageJSON)
        let position = try #require(page.positions.first)

        #expect(page.hasNext)
        #expect(page.nextCursor == "c2")
        #expect(page.positions.count == 1)

        #expect(position.conditionId == "0x94947a23")
        #expect(position.assetId == "10977723")
        #expect(position.marketId == "572480")
        #expect(position.eventTitle == "Who will Trump nominate as Fed Chair?")
        #expect(position.size == Decimal(string: "1870896.8476"))
        #expect(position.avgPrice == Decimal(string: "0.3157"))
        #expect(position.cashPnl == Decimal(string: "-590681.4236"))
        #expect(position.isRedeemable)
        #expect(position.isNegRisk)
        #expect(!position.isAcceptingOrders)
        #expect(position.resolutionStatus == .resolved)
        #expect(position.settlement == .lost)
    }

    @Test("The scheduled end arrives as a bare day and is read in the zone it was written in")
    func endDateIsACalendarDay() throws {
        let position = try #require(mapPage(Self.pageJSON).positions.first)
        let endDate = try #require(position.endDate)

        #expect(endDate == Date(timeIntervalSince1970: 1_798_675_200))
    }

    @Test("A row with a money string that cannot be read is dropped, and still counted")
    func rowThatCannotBeReadIsCounted() throws {
        let json = Data("""
        {
          "positions": [
            { "conditionId": "0x1", "assetId": "2", "currentValue": "twelve" },
            { "conditionId": "0x3", "assetId": "4" }
          ]
        }
        """.utf8)

        let page = try mapPage(json)

        #expect(page.positions.map(\.id) == ["0x3/4"])
        #expect(page.receivedCount == 2)
    }

    @Test("The proportion is carried as a fraction, the way the rest of the module carries one")
    func percentIsAFraction() throws {
        let position = try #require(mapPage(Self.pageJSON).positions.first)

        #expect(position.pnlRatio == Decimal(string: "-0.999999"))
    }

    @Test("A row the lookup could not enrich still maps, with selling closed")
    func degradedRowStillMaps() throws {
        let position = try #require(mapPage(Self.degradedJSON).positions.first)

        #expect(position.marketId == nil)
        #expect(position.eventId == nil)
        #expect(position.eventTitle == nil)
        #expect(!position.isAcceptingOrders)
        #expect(position.resolutionStatus == .unknown)
        #expect(position.settlement == nil)
        #expect(position.isRedeemable)
    }

    @Test("A settlement code this build does not know leaves the position unsettled")
    func unknownSettlementCodeIsNotASettlement() throws {
        let json = Data("""
        { "positions": [{ "conditionId": "0x1", "assetId": "2", "status": "SOMETHING_NEW" }] }
        """.utf8)

        let position = try #require(mapPage(json).positions.first)

        #expect(position.settlement == nil)
    }

    @Test("A missing cursor reads as the last page")
    func missingCursorIsTheLastPage() throws {
        #expect(try !mapPage(Self.degradedJSON).hasNext)
    }

    @Test("A closed row whose money cannot be read is dropped, and the page still says how many arrived")
    func closedRowThatCannotBeReadIsCounted() throws {
        let json = Data("""
        {
          "positions": [
            { "conditionId": "0x1", "assetId": "2", "realizedPnl": "not a number" },
            { "conditionId": "0x3", "assetId": "4" }
          ]
        }
        """.utf8)

        let page = try mapClosedPage(json)

        #expect(page.positions.count == 1)
        #expect(page.receivedCount == 2)
        #expect(page.positions.first?.conditionId == "0x3")
    }
}

// MARK: - Helpers

private extension PolymarketPositionsMappingTests {
    func mapPage(_ json: Data) throws -> PolymarketPositionsPage {
        try mapper.mapPositions(decoder.decode(PolymarketDTO.PositionsResponse.self, from: json))
    }

    func mapClosedPage(_ json: Data) throws -> PolymarketClosedPositionsPage {
        try mapper.mapClosedPositions(decoder.decode(PolymarketDTO.ClosedPositionsResponse.self, from: json))
    }
}

// MARK: - Fixtures

private extension PolymarketPositionsMappingTests {
    static let pageJSON = Data("""
    {
      "positions": [{
        "conditionId": "0x94947a23",
        "assetId": "10977723",
        "marketId": "572480",
        "eventId": "35908",
        "eventTitle": "Who will Trump nominate as Fed Chair?",
        "title": "Will Trump nominate Stephen Miran as the next Fed chair?",
        "icon": "https://polymarket-upload.s3/icon.jpg",
        "endDate": "2026-12-31",
        "outcome": "Yes",
        "size": "1870896.8476",
        "avgPrice": "0.3157",
        "curPrice": "0",
        "initialValue": "590681.4236",
        "currentValue": "0",
        "cashPnl": "-590681.4236",
        "percentPnl": "-99.9999",
        "realizedPnl": "-61428.7854",
        "redeemable": true,
        "negRisk": true,
        "acceptingOrders": false,
        "live": false,
        "resolutionStatus": "RESOLVED",
        "status": "LOST"
      }],
      "nextCursor": "c2"
    }
    """.utf8)

    static let degradedJSON = Data("""
    {
      "positions": [{
        "conditionId": "0x61b6",
        "assetId": "5133",
        "outcome": "No",
        "size": "10",
        "redeemable": true,
        "resolutionStatus": "SOMETHING_NEW"
      }]
    }
    """.utf8)
}
