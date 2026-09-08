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

            PolymarketOutcomePill(title: "\(outcomeTitle) \(priceText)", style: style)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Constants

private extension PolymarketOutcomeVoteView {
    enum Constants {
        static let spacing: CGFloat = 4
    }
}
