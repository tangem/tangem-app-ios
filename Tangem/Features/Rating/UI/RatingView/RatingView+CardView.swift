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

extension RatingView {
    struct CardView: View {
        typealias Rating = RatingModel.Rating

        let displayRating: Int
        var onRatingSelected: ((Rating) -> Void)?

        var body: some View {
            VStack(spacing: 12) {
                Text(Localization.swappingRateExperienceTitle)
                    .style(Fonts.Bold.footnote, color: Colors.Text.primary1)
                    .multilineTextAlignment(.center)

                StarsView(
                    displayRating: displayRating,
                    onRatingSelected: onRatingSelected
                )
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .background(Colors.Background.action)
            .cornerRadius(14)
        }
    }
}

// MARK: - Previews

#Preview {
    VStack(spacing: 16) {
        RatingView.CardView(displayRating: 0)
        RatingView.CardView(displayRating: 3)
        RatingView.CardView(displayRating: 5)
    }
    .padding(.horizontal, 16)
    .background(Color.gray.opacity(0.1))
}
