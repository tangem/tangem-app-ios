//
//  PolymarketMapperTests.swift
//  TangemPolymarketTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import Testing
@testable import TangemPolymarket

@Suite("PolymarketMapper")
struct PolymarketMapperTests {
    private let mapper = PolymarketMapper()
    private let decoder = JSONDecoder()

    // MARK: - Events page

    @Test("Events page decodes and maps into the domain model")
    func eventsPageMapping() throws {
        let dto = try decoder.decode(PolymarketDTO.EventsPageResponse.self, from: Self.eventsPageJSON)
        let page = mapper.mapEventsPage(dto)

        #expect(page.cursor == "cursor-2")
        #expect(page.hasNext)
        #expect(page.events.count == 1)

        let event = try #require(page.events.first)
        #expect(event.id == "0x-event-1")
        #expect(event.slug == "will-it-rain")
        #expect(event.title == "Will it rain?")
        #expect(event.status == .active)
        #expect(event.rulesURL == URL(string: "https://polymarket.com/rules/1"))
        #expect(event.volume == Decimal(stringValue: "1000.5"))
        #expect(event.startDate != nil)
        #expect(event.endDate != nil)
        #expect(event.totalMarketsCount == 3)
        #expect(event.hasMoreMarkets)
        #expect(event.displayMode == .groupedOutcomes)
        #expect(event.isNegRisk)

        let market = try #require(event.markets.first)
        #expect(market.id == "market-1")
        #expect(market.title == "Rain tomorrow?")
        #expect(market.outcomes.count == 2)

        let yes = try #require(market.outcomes.first)
        #expect(yes.assetId == "asset-yes")
        #expect(yes.title == "Yes")
        #expect(yes.probability == Decimal(stringValue: "0.62"))
    }

    @Test("Unknown status value falls back instead of failing the page")
    func unknownStatusFallback() throws {
        let dto = try decoder.decode(PolymarketDTO.EventsPageResponse.self, from: Self.eventsPageJSON)
        let page = mapper.mapEventsPage(dto)
        let market = try #require(page.events.first?.markets.first)
        #expect(market.status == .unknown("settling"))
    }

    @Test("An empty, blank or missing cursor ends the feed even when the page claims there is more", arguments: [
        #""cursor": """#,
        #""cursor": "   ""#,
        #""cursor": null"#,
    ])
    func blankCursorEndsFeed(cursorField: String) throws {
        let json = Data(#"{ "events": [], \#(cursorField), "hasNext": true }"#.utf8)
        let page = try mapper.mapEventsPage(decoder.decode(PolymarketDTO.EventsPageResponse.self, from: json))

        #expect(page.cursor == nil)
        #expect(!page.hasNext)
    }

    @Test("A page that says there is no more ends the feed even when it still carries a cursor")
    func lastPageEndsFeedDespiteCursor() throws {
        let json = Data(#"{ "events": [], "cursor": "cursor-2", "hasNext": false }"#.utf8)
        let page = try mapper.mapEventsPage(decoder.decode(PolymarketDTO.EventsPageResponse.self, from: json))

        #expect(page.cursor == nil)
        #expect(!page.hasNext)
    }

    @Test("A blank next cursor ends the positions, closed positions and activity lists", arguments: ["", "   "])
    func blankNextCursorEndsLists(cursor: String) throws {
        let positionsJSON = Data(#"{ "positions": [], "nextCursor": "\#(cursor)" }"#.utf8)
        let activityJSON = Data(#"{ "items": [], "nextCursor": "\#(cursor)" }"#.utf8)

        let positions = try mapper.mapPositions(decoder.decode(PolymarketDTO.PositionsResponse.self, from: positionsJSON))
        let closedPositions = try mapper.mapClosedPositions(decoder.decode(PolymarketDTO.ClosedPositionsResponse.self, from: positionsJSON))
        let activity = try mapper.mapActivity(decoder.decode(PolymarketDTO.ActivityResponse.self, from: activityJSON))

        #expect(!positions.hasNext)
        #expect(!closedPositions.hasNext)
        #expect(activity.nextCursor == nil)
    }

    @Test("Market statuses map active, closed and archived apart")
    func marketStatusMapping() throws {
        let json = #"""
        {"event":{"eventId":"e1","slug":"e1","title":"Event","markets":[
          {"id":"m1","question":"Open?","status":"active"},
          {"id":"m2","question":"Closed?","status":"closed"},
          {"id":"m3","question":"Archived?","status":"archived"}
        ]}}
        """#
        let dto = try decoder.decode(PolymarketDTO.EventResponse.self, from: Data(json.utf8))
        let event = mapper.mapEvent(dto.event)

        #expect(event.markets.map(\.status) == [.active, .closed, .archived])
    }

    // MARK: - Search

    @Test("Search response maps the page/total envelope")
    func searchMapping() throws {
        let dto = try decoder.decode(PolymarketDTO.EventsSearchResponse.self, from: Self.searchJSON)
        let result = mapper.mapSearchResult(dto)

        #expect(result.page == 0)
        #expect(result.total == 42)
        #expect(result.hasNext)
        #expect(result.events.count == 1)
        #expect(result.events.first?.id == "0x-event-9")
    }

    @Test("Empty and missing optional fields degrade gracefully")
    func minimalEventMapping() throws {
        let dto = try decoder.decode(PolymarketDTO.EventResponse.self, from: Self.minimalEventJSON)
        let event = mapper.mapEvent(dto.event)

        #expect(event.description == nil)
        #expect(event.rulesURL == nil)
        #expect(event.imageURL == nil)
        #expect(event.volume == nil)
        #expect(event.markets.isEmpty)
        #expect(event.totalMarketsCount == 0)
        #expect(!event.hasMoreMarkets)
        #expect(event.displayMode == .plainMarkets)
        #expect(event.teams.isEmpty)
    }

    @Test("Sports teams map with their abbreviation and side, nameless ones are dropped")
    func teamsMapping() throws {
        let json = #"""
        {"event":{"eventId":"810546","slug":"nfl-det-buf","title":"Lions vs. Bills","markets":[],"teams":[
          {"name":"Detroit Lions","abbreviation":"det","alias":"Lions","logo":"https://example.com/det.png","ordering":"away"},
          {"name":"Buffalo Bills","abbreviation":" ","alias":null,"logo":null,"ordering":"Home"},
          {"name":null,"abbreviation":"xxx","alias":null,"logo":null,"ordering":null}
        ]}}
        """#
        let dto = try decoder.decode(PolymarketDTO.EventResponse.self, from: Data(json.utf8))
        let event = mapper.mapEvent(dto.event)

        #expect(event.teams == [
            PolymarketTeam(name: "Detroit Lions", abbreviation: "det", alias: "Lions", logoURL: URL(string: "https://example.com/det.png"), side: .away),
            PolymarketTeam(name: "Buffalo Bills", abbreviation: nil, alias: nil, logoURL: nil, side: .home),
        ])
    }

    // MARK: - Dates

    @Test("Dates parse plain and fractional ISO-8601, and degrade on invalid input")
    func dateParsing() throws {
        #expect(mapper.date(from: nil) == nil)
        #expect(mapper.date(from: "") == nil)
        #expect(mapper.date(from: "not-a-date") == nil)

        let plain = try #require(mapper.date(from: "2026-07-01T00:00:00Z"))
        let fractional = try #require(mapper.date(from: "2026-07-01T00:00:00.123Z"))
        #expect(abs(fractional.timeIntervalSince(plain) - 0.123) < 0.0005)
    }

    @Test("A close time parses both as ISO-8601 and in Polymarket's space-separated form, with or without fractional seconds")
    func closeTimeParsing() {
        let closeTime = Date(timeIntervalSince1970: 1_788_034_666)

        #expect(mapper.date(from: "2026-08-29 20:17:46+00") == closeTime)
        #expect(mapper.date(from: "2026-08-29T20:17:46Z") == closeTime)
        #expect(mapper.date(from: "2026-08-29 20:17:46+00:00") == closeTime)
        #expect(mapper.date(from: "2026-08-29 20:17:46-03") == closeTime.addingTimeInterval(3 * 3600))

        let microseconds = mapper.date(from: "2026-08-29 20:17:46.899158+00").map { $0.timeIntervalSince(closeTime) }
        let tenths = mapper.date(from: "2026-08-29 20:17:46.8+00").map { $0.timeIntervalSince(closeTime) }

        #expect(microseconds.map { abs($0 - 0.899) < 0.001 } == true)
        #expect(tenths.map { abs($0 - 0.8) < 0.001 } == true)
    }

    @Test("A market's close time is read from an ISO or Polymarket string", arguments: [
        #""2026-08-29T20:17:46Z""#,
        #""2026-08-29 20:17:46+00""#,
        #""2026-08-29 20:17:46.000000+00""#,
    ])
    func marketCloseTimeMapping(closedTime: String) throws {
        let markets = try decodedMarkets(closedTime: closedTime)

        #expect(markets.first?.closedDate == Date(timeIntervalSince1970: 1_788_034_666))
        #expect(markets.last?.closedDate == nil)
    }

    @Test("A missing or unreadable close time is dropped without failing the event", arguments: [
        "null",
        #""soon""#,
        #""""#,
    ])
    func unexpectedCloseTimeIsDropped(closedTime: String) throws {
        let markets = try decodedMarkets(closedTime: closedTime)

        #expect(markets.count == 2)
        #expect(markets.first?.closedDate == nil)
        #expect(markets.first?.startDate == Date(timeIntervalSince1970: 1_787_490_038))
    }
}

// MARK: - Fixtures

private extension PolymarketMapperTests {
    func decodedMarkets(closedTime: String) throws -> [PolymarketMarket] {
        let json = """
        {"event":{"eventId":"1","slug":"match","title":"Match","markets":[
          {"id":"closed","question":"Closed?","startDate":"2026-08-23T13:00:38Z","closedTime":\(closedTime),"outcomes":[]},
          {"id":"open","question":"Open?","outcomes":[]}
        ]}}
        """
        let dto = try decoder.decode(PolymarketDTO.EventResponse.self, from: Data(json.utf8))

        return mapper.mapEvent(dto.event).markets
    }

    static let eventsPageJSON = Data("""
    {
      "events": [
        {
          "eventId": "0x-event-1",
          "slug": "will-it-rain",
          "title": "Will it rain?",
          "description": "Weather event",
          "polymarketRulesUrl": "https://polymarket.com/rules/1",
          "image": "https://img/1.png",
          "icon": "https://icon/1.png",
          "status": "active",
          "startDate": "2026-07-01T00:00:00Z",
          "endDate": "2026-08-01T00:00:00Z",
          "volume": 1000.5,
          "volume24hr": 50.0,
          "liquidity": 200.0,
          "totalMarketsCount": 3,
          "negRisk": true,
          "markets": [
            {
              "id": "market-1",
              "question": "Rain tomorrow?",
              "status": "settling",
              "negRisk": true,
              "volume": 10.0,
              "outcomes": [
                { "assetId": "asset-yes", "label": "Yes", "probability": 0.62 },
                { "assetId": "asset-no", "label": "No", "probability": 0.38 }
              ]
            }
          ]
        }
      ],
      "cursor": "cursor-2",
      "hasNext": true
    }
    """.utf8)

    static let searchJSON = Data("""
    {
      "events": [
        {
          "eventId": "0x-event-9",
          "slug": "election",
          "title": "Election winner",
          "totalMarketsCount": 1,
          "markets": []
        }
      ],
      "page": 0,
      "total": 42,
      "hasNext": true
    }
    """.utf8)

    static let minimalEventJSON = Data("""
    {
      "event": {
        "eventId": "0x-event-min",
        "slug": "min",
        "title": "Minimal"
      }
    }
    """.utf8)
}
