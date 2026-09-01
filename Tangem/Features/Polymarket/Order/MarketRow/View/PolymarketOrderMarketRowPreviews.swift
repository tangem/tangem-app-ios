//
//  PolymarketOrderMarketRowPreviews.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemPolymarket

private struct PolymarketOrderMarketRowShowcase: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                row(.shortQuestionStub, outcomeIndex: 0)
                row(.shortQuestionStub, outcomeIndex: 1)
                row(.longQuestionStub, outcomeIndex: 0)
                row(.longQuestionStub, outcomeIndex: 1)
                row(.noImageStub, outcomeIndex: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
        }
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
    }

    private func row(_ market: PolymarketMarket, outcomeIndex: Int) -> some View {
        PolymarketOrderMarketRow(model: .make(market: market, outcomeIndex: outcomeIndex))
    }
}

// MARK: - Stubs

private extension PolymarketMarket {
    static func stub(title: String, imageURL: URL?) -> PolymarketMarket {
        PolymarketMarket(
            id: title,
            title: title,
            groupItemTitle: nil,
            imageURL: imageURL,
            iconURL: nil,
            status: .active,
            isNegRisk: false,
            isAcceptingOrders: true,
            startDate: nil,
            endDate: nil,
            volume: 6_300_000,
            volume24h: nil,
            liquidity: nil,
            orderIndex: nil,
            outcomes: [
                PolymarketOutcome(assetId: "yes", title: "Yes", probability: 0.62),
                PolymarketOutcome(assetId: "no", title: "No", probability: 0.38),
            ]
        )
    }

    static let stubImageURL = URL(string: "https://polymarket.com/images/market.png")

    static let shortQuestionStub = stub(title: "Will Bitcoin hit $150k?", imageURL: stubImageURL)

    static let longQuestionStub = stub(
        title: "Will the Federal Reserve cut interest rates by at least 50 basis points before the end of 2026?",
        imageURL: stubImageURL
    )

    static let noImageStub = stub(title: "Will Uzbekistan reach the quarter-finals?", imageURL: nil)
}

// MARK: - Previews

#Preview("Showcase") {
    PolymarketOrderMarketRowShowcase()
}

#Preview("Showcase — Dark") {
    PolymarketOrderMarketRowShowcase()
        .preferredColorScheme(.dark)
}
