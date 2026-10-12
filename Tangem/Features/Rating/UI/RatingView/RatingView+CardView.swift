//
//  RatingView+CardView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUIUtils
import TangemAccessibilityIdentifiers

extension RatingView {
    struct CardView: View {
        typealias Rating = RatingModel.Rating

        let displayRating: Int
        let background: BackgroundStyle
        var onRatingSelected: ((Rating) -> Void)?

        var body: some View {
            VStack(spacing: 8) {
                Text(Localization.swappingRateExperienceTitle)
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                    .multilineTextAlignment(.center)

                StarsView(
                    displayRating: displayRating,
                    onRatingSelected: onRatingSelected
                )
            }
            .frame(maxWidth: .infinity)
            .roundedBackground(
                with: background.color,
                verticalPadding: background.verticalPadding,
                horizontalPadding: background.horizontalPadding,
                radius: background.cornerRadius
            )
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(RatingAccessibilityIdentifiers.block)
        }
    }
}
