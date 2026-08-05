//
//  PolymarketMapper+Search.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

extension PolymarketMapper {
    func mapSearchResult(_ dto: PolymarketDTO.EventsSearchResponse) -> PolymarketSearchResult {
        PolymarketSearchResult(
            events: dto.events.map(mapEvent),
            page: dto.page,
            total: dto.total,
            hasNext: dto.hasNext
        )
    }
}
