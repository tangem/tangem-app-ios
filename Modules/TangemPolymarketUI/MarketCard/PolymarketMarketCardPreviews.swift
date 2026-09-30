//
//  PolymarketMarketCardPreviews.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

private struct PolymarketMarketCardShowcase: View {
    var body: some View {
        ScrollView {
            VStack(spacing: Constants.spacing) {
                PolymarketMarketCard(model: .binaryStub)
                PolymarketMarketCard(model: .predictedStub)
                PolymarketMarketCard(model: .threeWayStub)
            }
            .padding(.horizontal, Constants.horizontalPadding)
            .padding(.vertical, Constants.spacing)
        }
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
    }
}

// MARK: - Constants

private extension PolymarketMarketCardShowcase {
    enum Constants {
        static let spacing: CGFloat = 24
        static let horizontalPadding: CGFloat = 16
    }
}

// MARK: - Stubs

private extension PolymarketMarketCard.Outcome {
    static func stub(_ title: String, _ priceText: String, _ style: PolymarketOutcomeStyle) -> Self {
        Self(id: title, title: title, priceText: priceText, style: style, onSelect: {})
    }
}

private extension PolymarketMarketCard.Model {
    static func stub(predictedText: String? = nil, outcomes: [PolymarketMarketCard.Outcome]) -> Self {
        Self(
            id: "market",
            title: "Uzbekistan",
            volumeText: "$6.3M",
            imageURL: nil,
            predictedText: predictedText,
            outcomes: outcomes
        )
    }

    static let binaryStub = stub(outcomes: [.stub("Yes", "15.4¢", .affirmative), .stub("No", "84.1¢", .negative)])

    static let predictedStub = stub(
        predictedText: "$50 for Yes",
        outcomes: [.stub("Yes", "15.4¢", .affirmative), .stub("No", "84.1¢", .negative)]
    )

    static let threeWayStub = stub(outcomes: [
        .stub("Yes", "15.4¢", .affirmative),
        .stub("Draw", "0.5¢", .negative),
        .stub("No", "84.1¢", .negative),
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
