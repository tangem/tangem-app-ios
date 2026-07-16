//
//  NewsArticleHeaderView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemFoundation

struct NewsArticleHeaderView: View {
    let article: NewsArticleModel
    var onShareTap: (() -> Void)?

    var body: some View {
        redesignContent
    }

    // MARK: - Redesign

    private var redesignContent: some View {
        VStack(alignment: .leading, spacing: .unit(.x4)) {
            scoreAndTimeLine

            Text(article.title)
                .style(Font.Tangem.Heading28.semibold, color: .Tangem.Text.Neutral.primary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            if article.categories.isNotEmpty {
                redesignTags
            }
        }
        .padding(.horizontal, .unit(.x1))
        .padding(.vertical, .unit(.x1_5))
    }

    private var redesignTags: some View {
        ScrollView(.horizontal) {
            HStack(spacing: .unit(.x1)) {
                ForEach(article.categories) { category in
                    redesignTag(title: category.name)
                        .fixedSize(horizontal: true, vertical: false)
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    private func redesignTag(title: String) -> some View {
        Text(title)
            .style(Font.Tangem.Body16.semibold, color: .Tangem.Text.Neutral.primary)
            .lineLimit(1)
            .padding(.horizontal, .unit(.x3))
            .padding(.vertical, .unit(.x2))
            .background(Color.Tangem.Markers.backgroundTintedGray, in: Capsule())
    }

    private var scoreAndTimeLine: some View {
        HStack(spacing: .unit(.x2)) {
            HStack(spacing: .unit(.x2)) {
                NewsRatingViewRedesign(
                    rating: article.score,
                    isHighlighted: true,
                    spacing: .unit(.x2),
                    font: Font.Tangem.Body16.medium
                )
            }

            Text("•")
                .style(Font.Tangem.Body16.medium, color: .Tangem.Text.Neutral.tertiary)

            HStack(spacing: .unit(.x2)) {
                Assets.Glyphs.calendar.image
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                    .foregroundStyle(Color.Tangem.Graphic.Neutral.secondary)

                Text(article.relativeTime)
                    .style(Font.Tangem.Body16.medium, color: .Tangem.Text.Neutral.secondary)
            }
        }
    }
}
