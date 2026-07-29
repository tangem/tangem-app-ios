//
//  PolymarketEventCardPreviews.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemPolymarket

private struct PolymarketEventCardShowcase: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                card(.multiMarketStub, isInActivePredicts: true)
                card(.multiMarketStub)
                card(.singleMarketStub, isInActivePredicts: true)
                card(.singleMarketStub)

                card(.multiMarketNoExtraStub, category: nil)

                PolymarketEventCardSkeleton()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
        }
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
    }

    private func card(
        _ event: PolymarketEvent,
        category: PolymarketCategory? = .sportStub,
        isInActivePredicts: Bool = false
    ) -> some View {
        PolymarketEventCard(
            model: .make(event: event, category: category, isInActivePredicts: isInActivePredicts, onSelectOutcome: { _, _ in })
        )
    }
}

// MARK: - Stubs

private extension PolymarketCategory {
    static let sportStub = PolymarketCategory(id: 1, label: "Sport", iconURL: nil)
}

private extension PolymarketOutcome {
    static func stub(id: String, title: String, probability: Decimal) -> PolymarketOutcome {
        PolymarketOutcome(assetId: id, title: title, probability: probability)
    }
}

private extension PolymarketMarket {
    static func stub(id: String, title: String, probability: Decimal) -> PolymarketMarket {
        PolymarketMarket(
            id: id,
            title: title,
            groupItemTitle: title,
            imageURL: nil,
            iconURL: nil,
            status: .active,
            isNegRisk: false,
            startDate: nil,
            endDate: nil,
            volume: 1_000_000,
            volume24h: nil,
            liquidity: nil,
            outcomes: [
                .stub(id: "\(id)-yes", title: "Yes", probability: probability),
                .stub(id: "\(id)-no", title: "No", probability: 1 - probability),
            ]
        )
    }
}

private extension PolymarketEvent {
    static func stub(markets: [PolymarketMarket], totalMarketsCount: Int) -> PolymarketEvent {
        PolymarketEvent(
            id: "event",
            slug: "who-will-win-fifa-world-cup-2026",
            title: "Who will win FIFA World Cup 2026 in the USA?",
            description: nil,
            rulesURL: nil,
            imageURL: nil,
            iconURL: nil,
            status: .active,
            startDate: nil,
            endDate: nil,
            volume: 6_300_000,
            volume24h: nil,
            liquidity: nil,
            totalMarketsCount: totalMarketsCount,
            isNegRisk: false,
            displayMode: .groupedOutcomes,
            markets: markets
        )
    }

    static let multiMarketStub = PolymarketEvent.stub(
        markets: [
            .stub(id: "france", title: "France", probability: 0.8),
            .stub(id: "uzbekistan", title: "Uzbekistan", probability: 0.64),
        ],
        totalMarketsCount: 6
    )

    static let singleMarketStub = PolymarketEvent.stub(
        markets: [.stub(id: "single", title: "Probability", probability: 0.8)],
        totalMarketsCount: 1
    )

    static let multiMarketNoExtraStub = PolymarketEvent.stub(
        markets: [
            .stub(id: "france", title: "France", probability: 0.8),
            .stub(id: "uzbekistan", title: "Uzbekistan", probability: 0.64),
        ],
        totalMarketsCount: 2
    )
}

// MARK: - Previews

#Preview("Showcase") {
    PolymarketEventCardShowcase()
}

#Preview("Showcase — Dark") {
    PolymarketEventCardShowcase()
        .preferredColorScheme(.dark)
}
