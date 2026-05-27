//
//  RatingView+StarsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

extension RatingView {
    struct StarsView: View {
        typealias Rating = RatingModel.Rating

        let displayRating: Int
        var onRatingSelected: ((Rating) -> Void)?

        var body: some View {
            HStack(spacing: 6.0) {
                ForEach(Rating.allCases, id: \.self) { rating in
                    starView(for: rating)
                }
            }
        }

        @ViewBuilder
        private func starView(for rating: Rating) -> some View {
            let image = Assets.DesignSystem.ratingStarEmpty.image
                .resizable()
                .frame(width: 32.0, height: 32.0)
                .foregroundStyle(color(for: rating))

            if let onRatingSelected {
                Button {
                    onRatingSelected(rating)
                } label: {
                    image
                }
                .buttonStyle(.plain)
            } else {
                image
            }
        }

        private func color(for rating: Rating) -> Color {
            rating.rawValue <= displayRating ? Color.Tangem.Graphic.Status.attention : Color.Tangem.Field.backgroundFocused
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    VStack(spacing: 20) {
        RatingView.StarsView(displayRating: 0)
        RatingView.StarsView(displayRating: 1)
        RatingView.StarsView(displayRating: 3)
        RatingView.StarsView(displayRating: 5)
    }
    .padding()
}
#endif
