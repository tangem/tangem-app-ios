//
//  RatingView+StarsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils
import TangemAccessibilityIdentifiers

extension RatingView {
    struct StarsView: View {
        typealias Rating = RatingModel.Rating

        let displayRating: Int
        var onRatingSelected: ((Rating) -> Void)?

        var body: some View {
            HStack(spacing: Constants.spacing) {
                ForEach(Rating.allCases, id: \.self) { rating in
                    starView(for: rating)
                }
            }
        }

        @ViewBuilder
        private func starView(for rating: Rating) -> some View {
            if let onRatingSelected {
                Button {
                    onRatingSelected(rating)
                } label: {
                    Self.starImage
                }
                .buttonStyle(StarPressStyle(isFilled: isFilled(rating), precedingStars: rating.rawValue - 1))
                .accessibilityIdentifier(RatingAccessibilityIdentifiers.star(rating.rawValue))
            } else {
                Self.starImage
                    .foregroundStyle(isFilled(rating) ? DesignSystem.Color.iconAccentYellow : DesignSystem.Color.iconTertiary)
                    .accessibilityIdentifier(RatingAccessibilityIdentifiers.star(rating.rawValue))
            }
        }

        static var starImage: some View {
            Assets.DesignSystem.ratingStarEmpty.image
                .resizable()
                .frame(size: CGSize(bothDimensions: Constants.starSize))
        }

        private func isFilled(_ rating: Rating) -> Bool {
            rating.rawValue <= displayRating
        }
    }
}

// MARK: - Constants

extension RatingView.StarsView {
    enum Constants {
        static let starSize: CGFloat = 32
        static let spacing: CGFloat = 6
    }
}

// MARK: - Press style

private struct StarPressStyle: ButtonStyle {
    typealias Constants = RatingView.StarsView.Constants

    let isFilled: Bool
    let precedingStars: Int

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(
                configuration.isPressed || isFilled
                    ? DesignSystem.Color.iconAccentYellow
                    : DesignSystem.Color.iconTertiary
            )
            .overlay(alignment: .leading) {
                if configuration.isPressed {
                    precedingStarsView
                }
            }
            .contentShape(Rectangle())
    }

    private var precedingStarsView: some View {
        HStack(spacing: Constants.spacing) {
            ForEach(0 ..< precedingStars, id: \.self) { _ in
                RatingView.StarsView.starImage
            }
        }
        .foregroundStyle(DesignSystem.Color.iconAccentYellow)
        .offset(x: -CGFloat(precedingStars) * (Constants.starSize + Constants.spacing))
        .allowsHitTesting(false)
    }
}
