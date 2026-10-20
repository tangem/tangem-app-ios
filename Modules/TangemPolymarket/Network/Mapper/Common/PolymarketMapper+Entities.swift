//
//  PolymarketMapper+Entities.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation

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
            isLive: dto.live ?? false,
            startDate: date(from: dto.startDate),
            endDate: date(from: dto.endDate),
            volume: dto.volume,
            volume24h: dto.volume24hr,
            liquidity: dto.liquidity,
            totalMarketsCount: dto.totalMarketsCount ?? dto.markets?.count ?? 0,
            isNegRisk: isNegRisk,
            displayMode: displayMode(from: dto.displayMode, isNegRisk: isNegRisk),
            markets: (dto.markets ?? []).map(mapMarket),
            teams: (dto.teams ?? []).compactMap(mapTeam)
        )
    }

    func mapTeam(_ dto: PolymarketDTO.Team) -> PolymarketTeam? {
        guard let name = dto.name?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
            return nil
        }

        return PolymarketTeam(
            name: name,
            abbreviation: dto.abbreviation?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
            alias: dto.alias?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
            logoURL: url(from: dto.logo),
            side: dto.ordering.flatMap { PolymarketTeam.Side(rawValue: $0.lowercased()) }
        )
    }

    func mapMarket(_ dto: PolymarketDTO.Market) -> PolymarketMarket {
        let version = PolymarketMarketVersion(apiValue: dto.version)

        return PolymarketMarket(
            id: dto.id,
            conditionId: dto.conditionId,
            version: version,
            title: dto.question,
            groupItemTitle: dto.groupItemTitle,
            imageURL: url(from: dto.image),
            iconURL: url(from: dto.icon),
            status: status(from: dto.status),
            isNegRisk: dto.negRisk ?? false,
            isAcceptingOrders: (dto.acceptingOrders ?? false) && version.isSupported,
            startDate: date(from: dto.startDate ?? dto.startDateIso),
            endDate: date(from: dto.endDate),
            volume: dto.volume,
            volume24h: dto.volume24hr,
            liquidity: dto.liquidity,
            orderIndex: dto.orderIndex,
            outcomes: (dto.outcomes ?? []).map(mapOutcome)
        )
    }

    func mapOutcome(_ dto: PolymarketDTO.Outcome) -> PolymarketOutcome {
        PolymarketOutcome(
            assetId: dto.assetId,
            legacyAssetId: dto.legacyAssetId?.nilIfEmpty,
            title: dto.label,
            probability: dto.probability
        )
    }
}
