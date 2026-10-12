//
//  PolymarketAPIProvider.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public protocol PolymarketAPIProvider {
    func categories(locale: String?) async throws -> [PolymarketCategory]

    func events(request: PolymarketEventsRequest) async throws -> PolymarketEventsPage

    func event(id: String) async throws -> PolymarketEvent

    func search(request: PolymarketSearchRequest) async throws -> PolymarketSearchResult

    func series() async throws -> [PolymarketSeries]

    func seriesEvents(seriesId: String) async throws -> PolymarketSeriesEvents

    func orderQuote(request: PolymarketOrderQuoteRequest) async throws -> PolymarketOrderQuote

    func positions(request: PolymarketPositionsRequest) async throws -> PolymarketPositionsPage

    func closedPositions(request: PolymarketClosedPositionsRequest) async throws -> PolymarketClosedPositionsPage

    func positionOutcome(request: PolymarketPositionOutcomeRequest) async throws -> PolymarketPosition?
}

public extension PolymarketAPIProvider {
    func categories() async throws -> [PolymarketCategory] {
        try await categories(locale: nil)
    }
}
