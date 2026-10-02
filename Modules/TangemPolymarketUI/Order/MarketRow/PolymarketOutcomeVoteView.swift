//
//  PolymarketOutcomeVoteView.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct PolymarketOutcomeVoteView: View {
    let outcomeTitle: String
    let priceText: String
    let nextPriceText: String?
    let isNextPriceLoading: Bool
    let style: PolymarketOutcomeStyle

    var body: some View {
        HStack(spacing: Constants.spacing) {
            Text(Localization.predictionPlaceYouVote)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                .lineLimit(1)

            pill
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var pill: some View {
        if isNextPriceLoading {
            PolymarketOutcomePill(title: outcomeTitle, style: style) {
                Shimmer()
                    .frame(width: Constants.pendingPriceWidth, height: Constants.pendingPriceHeight)
                    .clipShape(Capsule())
            }
        } else if let nextPriceText {
            PolymarketOutcomePill(title: "\(outcomeTitle) \(priceText) \(Constants.arrow) \(nextPriceText)", style: style)
        } else {
            PolymarketOutcomePill(title: "\(outcomeTitle) \(priceText)", style: style)
        }
    }
}

// MARK: - Constants

private extension PolymarketOutcomeVoteView {
    enum Constants {
        static let spacing: CGFloat = 4
        static let arrow = "\u{2192}"
        static let pendingPriceWidth: CGFloat = 64
        static let pendingPriceHeight: CGFloat = 10
    }
}
