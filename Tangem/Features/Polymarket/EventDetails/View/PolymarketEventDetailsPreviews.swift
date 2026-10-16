//
//  PolymarketEventDetailsPreviews.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemPolymarket
import TangemPolymarketUI
import TangemUI

private struct PolymarketEventDetailsShowcase: View {
    let content: PolymarketEventDetailsContent

    @State private var isDescriptionExpanded = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header

                VStack(spacing: 8) {
                    ForEach(content.activeMarkets) { model in
                        PolymarketMarketCard(model: model)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)

                if let description = content.description {
                    PolymarketExpandableDescription(
                        text: description,
                        isExpanded: isDescriptionExpanded,
                        onReadMore: { isDescriptionExpanded = true }
                    )
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }
        }
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(content.title)
                .style(DesignSystem.Font.headingMediumToken, color: DesignSystem.Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            WrappingHStack(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
                if content.isLive {
                    Badge(label: "Live", accessibilityLabel: nil)
                        .size(.x4)
                        .variant(.solid)
                        .appearance(.success)
                        .slotStart(DesignSystem.Icons.Dot.filled12)
                }

                if let categoryName = content.categoryName {
                    Badge(label: categoryName, accessibilityLabel: nil)
                        .size(.x4)
                        .variant(.tinted)
                        .appearance(.neutral)
                }

                if let volumeText = content.volumeText {
                    Text("Total volume: \(volumeText)")
                        .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

// MARK: - Stubs

private extension PolymarketOutcome {
    static func stub(id: String, title: String, probability: Decimal) -> PolymarketOutcome {
        PolymarketOutcome(assetId: id, title: title, probability: probability)
    }
}

private extension PolymarketMarket {
    static func stub(id: String, title: String, probability: Decimal, status: PolymarketEventStatus = .active) -> PolymarketMarket {
        PolymarketMarket(
            id: id,
            conditionId: nil,
            title: "Will \(title) win the 2026 FIFA World Cup?",
            groupItemTitle: title,
            imageURL: nil,
            iconURL: nil,
            status: status,
            isNegRisk: true,
            isAcceptingOrders: status == .active,
            startDate: nil,
            endDate: nil,
            volume: 300_000,
            volume24h: nil,
            liquidity: nil,
            orderIndex: 0,
            outcomes: [
                .stub(id: "\(id)-yes", title: "Yes", probability: probability),
                .stub(id: "\(id)-no", title: "No", probability: 1 - probability),
            ]
        )
    }
}

private extension PolymarketEvent {
    static let stub = PolymarketEvent(
        id: "event",
        slug: "who-will-win-fifa-world-cup-2026",
        title: "Who will win FIFA World Cup 2026 in the USA?",
        description: """
        This market will resolve to "Brendson Ribeiro" if Brendson Ribeiro is officially declared the winner of \
        the fight against Magomed Ankalaev. Any other outcome, including a draw, a no-contest or a cancellation, \
        resolves the market to the opposing side.
        """,
        rulesURL: nil,
        imageURL: nil,
        iconURL: nil,
        status: .active,
        isLive: true,
        startDate: Date(timeIntervalSince1970: 1_752_264_000),
        endDate: Date(timeIntervalSince1970: 1_784_664_000),
        volume: 6_300_000,
        volume24h: 128_000,
        liquidity: nil,
        totalMarketsCount: 4,
        isNegRisk: true,
        displayMode: .groupedOutcomes,
        markets: [
            .stub(id: "france", title: "France", probability: 0.25),
            .stub(id: "germany", title: "Germany", probability: 0.15),
            .stub(id: "uzbekistan", title: "Uzbekistan", probability: 0.15),
            .stub(id: "argentina", title: "Argentina", probability: 0.15),
            .stub(id: "brazil", title: "Brazil", probability: 0.1, status: .closed),
        ]
    )
}

// MARK: - Previews

#Preview("Showcase") {
    PolymarketEventDetailsShowcase(
        content: .make(
            event: .stub,
            category: PolymarketCategory(id: 1, label: "Sport", icon: .sports),
            onSelectOutcome: { _, _ in }
        )
    )
}

#Preview("Showcase — Dark") {
    PolymarketEventDetailsShowcase(
        content: .make(
            event: .stub,
            category: PolymarketCategory(id: 1, label: "Sport", icon: .sports),
            onSelectOutcome: { _, _ in }
        )
    )
    .preferredColorScheme(.dark)
}
