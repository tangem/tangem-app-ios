//
//  NewsRatingView.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

public struct NewsRatingViewRedesign: View {
    private enum RatingFont {
        case legacy(TangemFontStyle)
        case token(TangemTypographyToken)
    }

    private let rating: String
    private let isHighlighted: Bool
    private let spacing: CGFloat
    private let font: RatingFont

    public init(rating: String, isHighlighted: Bool, spacing: CGFloat = 3.0, font: TangemFontStyle = Font.Tangem.Caption12.semibold) {
        self.rating = rating
        self.isHighlighted = isHighlighted
        self.spacing = spacing
        self.font = .legacy(font)
    }

    public init(rating: String, isHighlighted: Bool, spacing: CGFloat = 3.0, font: TangemTypographyToken) {
        self.rating = rating
        self.isHighlighted = isHighlighted
        self.spacing = spacing
        self.font = .token(font)
    }

    public var body: some View {
        HStack(spacing: spacing) {
            starIcon
            ratingText
        }
    }

    @ViewBuilder
    private var ratingText: some View {
        switch font {
        case .legacy(let style):
            Text(rating).style(style, color: legacyTextColor)
        case .token(let token):
            Text(rating).style(token, color: tokenTextColor)
        }
    }

    private var legacyTextColor: Color {
        isHighlighted ? .Tangem.Text.Status.attention : .Tangem.Text.Neutral.secondary
    }

    private var tokenTextColor: Color {
        isHighlighted ? DesignSystem.Color.textAccentYellow : DesignSystem.Color.textSecondary
    }

    private var starIcon: some View {
        Assets.newsRankIcon.image
            .renderingMode(.template)
            .resizable()
            .frame(size: .init(bothDimensions: Layout.iconSize))
            .foregroundStyle(iconColor)
    }

    private var iconColor: Color {
        switch font {
        case .legacy:
            isHighlighted ? Color.Tangem.Graphic.Status.attention : .Tangem.Graphic.Neutral.tertiary
        case .token:
            isHighlighted ? DesignSystem.Color.iconAccentYellow : DesignSystem.Color.iconSecondary
        }
    }

    private enum Layout {
        static let iconSize: CGFloat = 16
    }
}

#Preview("New") {
    VStack(spacing: 20) {
        NewsRatingViewRedesign(rating: "8.6", isHighlighted: true)
        NewsRatingViewRedesign(rating: "8.6", isHighlighted: false)
    }
}

public struct NewsRatingView: View {
    private let rating: String
    private let timeAgo: String

    public init(rating: String, timeAgo: String) {
        self.rating = rating
        self.timeAgo = timeAgo
    }

    public var body: some View {
        HStack(spacing: Layout.contentSpacing) {
            starIcon

            Text(rating)
                .style(Fonts.Regular.footnote, color: Colors.Text.secondary)

            dotSeparator

            Text(timeAgo)
                .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
        }
    }

    // MARK: - Components

    private var starIcon: some View {
        ZStack {
            Circle()
                .fill(Colors.Icon.attention)
                .frame(size: Layout.starCircleSize)

            Assets.star.image
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(Colors.Icon.constant)
                .frame(size: Layout.starIconSize)
        }
    }

    private var dotSeparator: some View {
        Circle()
            .fill(Colors.Text.tertiary)
            .frame(size: Layout.dotSize)
    }

    private enum Layout {
        static let contentSpacing: CGFloat = 4
        static let starCircleSize: CGSize = .init(width: 12, height: 12)
        static let starIconSize: CGSize = .init(width: 8, height: 8)
        static let dotSize: CGSize = .init(width: 4, height: 4)
    }
}

// MARK: - Previews

@available(iOS 17.0, *)
#Preview(traits: .sizeThatFitsLayout) {
    VStack(spacing: 20) {
        NewsRatingView(rating: "9.1", timeAgo: "1h ago")

        NewsRatingView(rating: "8.5", timeAgo: "2h ago")

        NewsRatingView(rating: "7.2", timeAgo: "3d ago")
    }
    .padding()
    .background(Colors.Background.primary)
}
