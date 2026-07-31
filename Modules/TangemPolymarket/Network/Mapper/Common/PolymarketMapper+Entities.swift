//
//  PolymarketMapper+Entities.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

extension PolymarketMapper {
    func mapEvent(_ dto: PolymarketDTO.Event) -> PolymarketEvent {
        let isNegRisk = dto.negRisk ?? false

        return PolymarketEvent(
            id: dto.eventId,
            slug: dto.slug,
            title: dto.title,
            description: dto.description,
            rulesURL: url(from: dto.polymarketRulesUrl),
            imageURL: url(from: dto.image),
            iconURL: url(from: dto.icon),
            status: status(from: dto.status),
            startDate: date(from: dto.startDate),
            endDate: date(from: dto.endDate),
            volume: dto.volume,
            volume24h: dto.volume24hr,
            liquidity: dto.liquidity,
            totalMarketsCount: dto.totalMarketsCount ?? dto.markets?.count ?? 0,
            isNegRisk: isNegRisk,
            displayMode: displayMode(from: dto.displayMode, isNegRisk: isNegRisk),
            markets: (dto.markets ?? []).map(mapMarket)
        )
    }

    func mapMarket(_ dto: PolymarketDTO.Market) -> PolymarketMarket {
        PolymarketMarket(
            id: dto.id,
            title: dto.question,
            groupItemTitle: dto.groupItemTitle,
            imageURL: url(from: dto.image),
            iconURL: url(from: dto.icon),
            status: status(from: dto.status),
            isNegRisk: dto.negRisk ?? false,
            startDate: date(from: dto.startDateIso ?? dto.startDate),
            endDate: date(from: dto.endDateIso ?? dto.endDate),
            volume: dto.volume,
            volume24h: dto.volume24hr,
            liquidity: dto.liquidity,
            outcomes: (dto.outcomes ?? []).map(mapOutcome)
        )
    }

    func mapOutcome(_ dto: PolymarketDTO.Outcome) -> PolymarketOutcome {
        PolymarketOutcome(
            assetId: dto.assetId,
            title: dto.label,
            probability: dto.probability
        )
    }
}
