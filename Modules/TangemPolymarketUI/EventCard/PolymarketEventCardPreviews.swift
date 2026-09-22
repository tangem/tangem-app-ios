//
//  PolymarketEventCardPreviews.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

private struct PolymarketEventCardShowcase: View {
    var body: some View {
        ScrollView {
            VStack(spacing: Constants.spacing) {
                PolymarketEventCard(model: .multiMarketInPredictsStub)
                PolymarketEventCard(model: .multiMarketStub)
                PolymarketEventCard(model: .singleMarketInPredictsStub)
                PolymarketEventCard(model: .singleMarketStub)
                PolymarketEventCard(model: .multiMarketNoExtraStub)

                PolymarketEventCardSkeleton()
            }
            .padding(.horizontal, Constants.horizontalPadding)
            .padding(.vertical, Constants.spacing)
        }
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
    }
}

// MARK: - Constants

private extension PolymarketEventCardShowcase {
    enum Constants {
        static let spacing: CGFloat = 24
        static let horizontalPadding: CGFloat = 16
    }
}

// MARK: - Stubs

private extension PolymarketEventCard.Row {
    static func stub(_ title: String, _ subtitle: String) -> Self {
        Self(
            id: title,
            title: title,
            subtitle: subtitle,
            outcomes: [
                PolymarketEventCard.Outcome(id: "\(title)-yes", title: "Yes", style: .affirmative, onSelect: {}),
                PolymarketEventCard.Outcome(id: "\(title)-no", title: "No", style: .negative, onSelect: {}),
            ]
        )
    }
}

private extension PolymarketEventCard.Model {
    static func stub(
        variant: PolymarketEventCard.Variant,
        rows: [PolymarketEventCard.Row],
        additionalOutcomesCount: Int,
        isInActivePredicts: Bool = false,
        category: PolymarketEventCard.Category? = PolymarketEventCard.Category(name: "Sport", iconURL: nil)
    ) -> Self {
        Self(
            id: "event",
            title: "Who will win FIFA World Cup 2026 in the USA?",
            category: category,
            volumeText: "$6.3M",
            imageURL: nil,
            variant: variant,
            rows: rows,
            additionalOutcomesCount: additionalOutcomesCount,
            isInActivePredicts: isInActivePredicts
        )
    }

    static let multiMarketRows: [PolymarketEventCard.Row] = [.stub("France", "80%"), .stub("Uzbekistan", "64%")]

    static let multiMarketStub = stub(variant: .multiMarket, rows: multiMarketRows, additionalOutcomesCount: 4)

    static let multiMarketInPredictsStub = stub(
        variant: .multiMarket,
        rows: multiMarketRows,
        additionalOutcomesCount: 4,
        isInActivePredicts: true
    )

    static let singleMarketStub = stub(
        variant: .singleMarket,
        rows: [.stub("Probability", "80%")],
        additionalOutcomesCount: 0
    )

    static let singleMarketInPredictsStub = stub(
        variant: .singleMarket,
        rows: [.stub("Probability", "80%")],
        additionalOutcomesCount: 0,
        isInActivePredicts: true
    )

    static let multiMarketNoExtraStub = stub(
        variant: .multiMarket,
        rows: multiMarketRows,
        additionalOutcomesCount: 0,
        category: nil
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
