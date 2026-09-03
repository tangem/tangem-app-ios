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
import TangemUIUtils

struct PolymarketOutcomeVoteView: View {
    let outcomeTitle: String
    let priceText: String
    let style: PolymarketOutcomeStyle

    var body: some View {
        HStack(spacing: Constants.spacing) {
            Text(Localization.predictionPlaceYouVote)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                .lineLimit(1)

            Text("\(outcomeTitle) \(priceText)")
                .style(DesignSystem.Font.captionMediumToken, color: style.foregroundColor)
                .lineLimit(1)
                .padding(.horizontal, Constants.pillHorizontalPadding)
                .frame(minHeight: Constants.pillMinHeight)
                .background(style.backgroundColor, in: Capsule())
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Constants

private extension PolymarketOutcomeVoteView {
    enum Constants {
        static let spacing: CGFloat = 4
        static let pillHorizontalPadding: CGFloat = 8
        static let pillMinHeight: CGFloat = 24
    }
}
