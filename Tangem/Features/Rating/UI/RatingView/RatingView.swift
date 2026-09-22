//
//  RatingView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct RatingView: View {
    @ObservedObject var viewModel: RatingViewModel

    var background: BackgroundStyle = .plate

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                skeletonView
            case .unrated:
                CardView(
                    displayRating: viewModel.displayRating,
                    background: background,
                    onRatingSelected: viewModel.ratingSelectionHandler
                )
            case .submitting, .rated, .submitted:
                CardView(displayRating: viewModel.displayRating, background: background)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.state)
    }
}

private extension RatingView {
    // MARK: - Subviews

    var skeletonView: some View {
        CardView(displayRating: 0, background: background)
            .hidden()
            .overlay {
                background.color
                    .cornerRadiusContinuous(background.cornerRadius)
                    .skeletonable(isShown: true, radius: background.cornerRadius)
            }
    }
}

// MARK: - Background style

extension RatingView {
    struct BackgroundStyle {
        let color: Color
        let cornerRadius: CGFloat
        let verticalPadding: CGFloat
        let horizontalPadding: CGFloat

        static let plate = BackgroundStyle(
            color: DesignSystem.Color.bgTertiary,
            cornerRadius: 24,
            verticalPadding: 16,
            horizontalPadding: 16
        )

        static let legacy = BackgroundStyle(
            color: Colors.Background.action,
            cornerRadius: 14,
            verticalPadding: 12,
            horizontalPadding: 14
        )
    }
}
