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
}

// MARK: - Fixtures

private extension PolymarketMapperTests {
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
