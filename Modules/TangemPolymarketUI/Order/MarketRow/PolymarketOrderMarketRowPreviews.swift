//
//  PolymarketOrderMarketRowPreviews.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

private struct PolymarketOrderMarketRowShowcase: View {
    var body: some View {
        ScrollView {
            VStack(spacing: Constants.spacing) {
                PolymarketOrderMarketRow(model: .affirmativeStub)
                PolymarketOrderMarketRow(model: .negativeStub)
                PolymarketOrderMarketRow(model: .longQuestionStub)
                PolymarketOrderMarketRow(model: .noImageStub)
            }
            .padding(.horizontal, Constants.horizontalPadding)
            .padding(.vertical, Constants.spacing)
        }
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
    }
}

// MARK: - Constants

private extension PolymarketOrderMarketRowShowcase {
    enum Constants {
        static let spacing: CGFloat = 24
        static let horizontalPadding: CGFloat = 16
    }
}

// MARK: - Stubs

private extension PolymarketOrderMarketRow.Model {
    static func stub(
        question: String = "Will Bitcoin hit $150k?",
        imageURL: URL? = stubImageURL,
        outcomeTitle: String = "Yes",
        outcomePriceText: String = "62.3¢",
        outcomeStyle: PolymarketOutcomeStyle = .affirmative
    ) -> Self {
        Self(
            question: question,
            imageURL: imageURL,
            outcomeTitle: outcomeTitle,
            outcomePriceText: outcomePriceText,
            outcomeStyle: outcomeStyle
        )
    }

    static let stubImageURL = URL(string: "https://polymarket.com/images/market.png")

    static let affirmativeStub = stub()

    static let negativeStub = stub(outcomeTitle: "No", outcomePriceText: "37.7¢", outcomeStyle: .negative)

    static let longQuestionStub = stub(
        question: "Will the Federal Reserve cut interest rates by at least 50 basis points before the end of 2026?"
    )

    static let noImageStub = stub(question: "Will Uzbekistan reach the quarter-finals?", imageURL: nil)
}

// MARK: - Previews

#Preview("Showcase") {
    PolymarketOrderMarketRowShowcase()
}

#Preview("Showcase — Dark") {
    PolymarketOrderMarketRowShowcase()
        .preferredColorScheme(.dark)
}
