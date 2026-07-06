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
    private let rating: String
    private let isHighlighted: Bool
    private let spacing: CGFloat
    private let font: TangemFontStyle

    public init(rating: String, isHighlighted: Bool, spacing: CGFloat = 3.0, font: TangemFontStyle = Font.Tangem.Caption12.semibold) {
        self.rating = rating
        self.isHighlighted = isHighlighted
        self.spacing = spacing
        self.font = font
    }

    public var body: some View {
        HStack(spacing: spacing) {
            starIcon
            Text(rating)
                .style(
                    font,
                    color: isHighlighted ? .Tangem.Text.Status.attention : .Tangem.Text.Neutral.secondary
                )
        }
    }

    private var starIcon: some View {
        Assets.newsRankIcon.image
            .renderingMode(.template)
            .resizable()
            .frame(size: .init(bothDimensions: Layout.iconSize))
            .foregroundStyle(isHighlighted ? Color.Tangem.Graphic.Status.attention : .Tangem.Graphic.Neutral.tertiary)
    }

    private enum Layout {
        static let iconSize: CGFloat = .unit(.x4)
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
