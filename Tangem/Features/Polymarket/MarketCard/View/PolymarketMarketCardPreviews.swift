//
//  PolymarketMarketCardPreviews.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemPolymarket

private struct PolymarketMarketCardShowcase: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                card(.binaryStub)
                card(.binaryStub, predictedText: "$50 for Yes")
                card(.threeWayStub)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
        }
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
    }

    private func card(_ market: PolymarketMarket, predictedText: String? = nil) -> some View {
        PolymarketMarketCard(
            model: .make(market: market, predictedText: predictedText, onSelectOutcome: { _ in })
        )
    }
}

// MARK: - Stubs

private extension PolymarketMarket {
    static func stub(outcomes: [PolymarketOutcome]) -> PolymarketMarket {
        PolymarketMarket(
            id: "market",
            title: "Uzbekistan",
            groupItemTitle: "Uzbekistan",
            imageURL: nil,
            iconURL: nil,
            status: .active,
            isNegRisk: false,
            startDate: nil,
            endDate: nil,
            volume: 6_300_000,
            volume24h: nil,
            liquidity: nil,
            outcomes: outcomes
        )
    }

    static let binaryStub = stub(outcomes: [
        PolymarketOutcome(assetId: "yes", title: "Yes", probability: 0.15),
        PolymarketOutcome(assetId: "no", title: "No", probability: 0.84),
    ])

    static let threeWayStub = stub(outcomes: [
        PolymarketOutcome(assetId: "yes", title: "Yes", probability: 0.15),
        PolymarketOutcome(assetId: "draw", title: "Draw", probability: 0.01),
        PolymarketOutcome(assetId: "no", title: "No", probability: 0.84),
    ])
}

// MARK: - Previews

#Preview("Showcase") {
    PolymarketMarketCardShowcase()
}

#Preview("Showcase — Dark") {
    PolymarketMarketCardShowcase()
        .preferredColorScheme(.dark)
}
