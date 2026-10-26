//
//  PolymarketMapper+EventSports.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension PolymarketMapper {
    func mapEventSports(_ dto: PolymarketDTO.EventSports) -> PolymarketEventSports {
        let tags = Set((dto.tags ?? []).compactMap(\.slug))
        let moneyline = (dto.markets ?? [])
            .filter { $0.sportsMarketType == EventSportsConstants.moneylineMarketType }
            .compactMap { $0.conditionId?.lowercased() }

        return PolymarketEventSports(
            isSports: tags.contains(EventSportsConstants.sportsTag),
            moneylineConditionIds: Set(moneyline)
        )
    }
}

// MARK: - Constants

private enum EventSportsConstants {
    static let sportsTag = "sports"
    static let moneylineMarketType = "moneyline"
}
