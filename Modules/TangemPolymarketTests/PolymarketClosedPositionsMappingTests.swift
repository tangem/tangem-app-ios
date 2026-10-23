//
//  PolymarketClosedPositionsMappingTests.swift
//  TangemPolymarketTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemPolymarket

@Suite("Polymarket closed positions mapping")
struct PolymarketClosedPositionsMappingTests {
    private let mapper = PolymarketMapper()
    private let decoder = JSONDecoder()

    @Test("A closed page decodes with its money read as decimals and its ending read as a status")
    func pageMapping() throws {
        let page = try mapPage(Self.pageJSON)
        let position = try #require(page.positions.first)

        #expect(page.hasNext)
        #expect(page.nextCursor == "c2")
        #expect(position.conditionId == "0x94947a23")
        #expect(position.assetId == "10977723")
        #expect(position.title == "Will Trump nominate Stephen Miran as the next Fed chair?")
        #expect(position.slug == "will-trump-nominate-stephen-miran")
        #expect(position.outcome == "Yes")
        #expect(position.avgPrice == Decimal(string: "0.3157"))
        #expect(position.curPrice == 1)
        #expect(position.totalBought == Decimal(string: "1870896.8476"))
        #expect(position.realizedPnl == Decimal(string: "-61428.7854"))
        #expect(position.status == .won)
    }

    @Test("The four endings the backend names are recognised", arguments: [
        ("\"CLOSED\"", PolymarketClosedPositionStatus.closed),
        ("\"WON\"", .won),
        ("\"LOST\"", .lost),
        ("\"SPLIT\"", .split),
    ])
    func statusIsRecognised(raw: String, expected: PolymarketClosedPositionStatus) throws {
        #expect(try position(status: raw).status == expected)
    }

    @Test("An ending added later reads as unknown rather than as one of the four")
    func unknownStatusIsKeptApart() throws {
        #expect(try position(status: "\"SOMETHING_NEW\"").status == .unknown)
    }

    @Test("A status the answer omits is as unrecognised as one it does not name")
    func absentStatusIsUnknown() throws {
        #expect(try position(status: "null").status == .unknown)
    }

    @Test("The identity separates both of its parts, so neighbouring pairs cannot collide")
    func identityIsSeparated() throws {
        #expect(try #require(mapPage(Self.pageJSON).positions.first).id == "0x94947a23/10977723")
    }

    @Test("A page without a cursor ends the list")
    func missingCursorIsTheLastPage() throws {
        #expect(try !mapPage(Data(#"{ "positions": [] }"#.utf8)).hasNext)
    }
}

// MARK: - Helpers

private extension PolymarketClosedPositionsMappingTests {
    func mapPage(_ json: Data) throws -> PolymarketClosedPositionsPage {
        try mapper.mapClosedPositions(decoder.decode(PolymarketDTO.ClosedPositionsResponse.self, from: json))
    }

    func position(status: String) throws -> PolymarketClosedPosition {
        let json = Data("""
        { "positions": [{ "conditionId": "0x1", "assetId": "2", "status": \(status) }] }
        """.utf8)

        return try #require(mapPage(json).positions.first)
    }
}

// MARK: - Fixtures

private extension PolymarketClosedPositionsMappingTests {
    static let pageJSON = Data("""
    {
      "positions": [{
        "conditionId": "0x94947a23",
        "assetId": "10977723",
        "title": "Will Trump nominate Stephen Miran as the next Fed chair?",
        "slug": "will-trump-nominate-stephen-miran",
        "icon": "https://polymarket-upload.s3/icon.jpg",
        "closedAt": "2026-03-22T10:15:00Z",
        "outcome": "Yes",
        "avgPrice": "0.3157",
        "curPrice": "1",
        "totalBought": "1870896.8476",
        "realizedPnl": "-61428.7854",
        "status": "WON"
      }],
      "nextCursor": "c2"
    }
    """.utf8)
}
