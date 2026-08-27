//
//  PolymarketMapper+Series.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

extension PolymarketMapper {
    func mapSeries(_ dto: PolymarketDTO.Series) -> PolymarketSeries {
        PolymarketSeries(
            id: dto.id,
            label: dto.label,
            iconURL: url(from: dto.icon)
        )
    }

    func mapSeriesEvents(_ dto: PolymarketDTO.SeriesEventsResponse) -> PolymarketSeriesEvents {
        PolymarketSeriesEvents(
            seriesId: dto.seriesId,
            events: dto.events.map(mapEvent)
        )
    }
}
