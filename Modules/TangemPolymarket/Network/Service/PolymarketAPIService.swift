//
//  PolymarketAPIService.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol PolymarketAPIService {
    func categories(locale: String?) async throws -> PolymarketDTO.CategoriesResponse
    func events(request: PolymarketEventsRequest) async throws -> PolymarketDTO.EventsPageResponse
    func event(id: String) async throws -> PolymarketDTO.EventResponse
    func search(request: PolymarketSearchRequest) async throws -> PolymarketDTO.EventsSearchResponse
    func series() async throws -> PolymarketDTO.SeriesResponse
    func seriesEvents(seriesId: String) async throws -> PolymarketDTO.SeriesEventsResponse
}
