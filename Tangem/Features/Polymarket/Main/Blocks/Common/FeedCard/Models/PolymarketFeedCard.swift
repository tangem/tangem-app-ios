//
//  PolymarketFeedCard.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket
import TangemPolymarketUI

enum PolymarketFeedCard: Equatable, Identifiable {
    case regular(PolymarketEventCard.Model)
    case liveGame(PolymarketLiveGameCard.Model)

    var id: String {
        switch self {
        case .regular(let model): model.id
        case .liveGame(let model): model.id
        }
    }

    static func make(
        event: PolymarketEvent,
        usesPhaseTwoCards: Bool,
        liveGame: PolymarketLiveGame?,
        liveQuotesByAssetId: [String: PolymarketOutcomeQuote],
        onSelectOutcome: @escaping (PolymarketMarket, PolymarketOutcome) -> Void
    ) -> Self {
        if usesPhaseTwoCards, let liveGameCard = PolymarketLiveGameCard.Model.make(
            event: event,
            liveGame: liveGame,
            liveQuotesByAssetId: liveQuotesByAssetId,
            onSelectOutcome: onSelectOutcome
        ) {
            return .liveGame(liveGameCard)
        }

        return .regular(
            .make(
                event: event,
                category: nil,
                isInActivePredicts: false,
                liveQuotesByAssetId: liveQuotesByAssetId,
                isLiveBadgePulsing: usesPhaseTwoCards,
                outcomeLabelStyle: usesPhaseTwoCards ? .compact : .bulletSeparated,
                onSelectOutcome: onSelectOutcome
            )
        )
    }
}
