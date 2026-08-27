//
//  PolymarketMapper+Feed.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

extension PolymarketMapper {
    func mapEventsPage(_ dto: PolymarketDTO.EventsPageResponse) -> PolymarketEventsPage {
        PolymarketEventsPage(
            events: dto.events.map(mapEvent),
            cursor: dto.cursor,
            hasNext: dto.hasNext
        )
    }
}
