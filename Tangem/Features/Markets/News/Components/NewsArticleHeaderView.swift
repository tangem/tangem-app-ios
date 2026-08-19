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
import TangemUIUtils
import TangemFoundation

struct NewsArticleHeaderView: View {
    let article: NewsArticleModel
    var onShareTap: (() -> Void)?

    var body: some View {
        redesignContent
    }

    // MARK: - Redesign

    private var redesignContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            scoreAndTimeLine

            Text(article.title)
                .style(DesignSystem.Font.headingMediumToken, color: DesignSystem.Color.textPrimary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            if article.categories.isNotEmpty {
                redesignTags
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 6)
    }

    private var redesignTags: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 4) {
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
            .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
            .lineLimit(1)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(DesignSystem.Color.bgOpaquePrimary, in: Capsule())
    }

    private var scoreAndTimeLine: some View {
        HStack(spacing: 8) {
            HStack(spacing: 8) {
                NewsRatingViewRedesign(
                    rating: article.score,
                    isHighlighted: true,
                    spacing: 8,
                    font: DesignSystem.Font.bodyMediumToken
                )
            }

            Text("•")
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textSecondary)

            HStack(spacing: 8) {
                Assets.Glyphs.calendar.image
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                    .foregroundStyle(DesignSystem.Color.iconSecondary)

                Text(article.relativeTime)
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textSecondary)
            }
        }
    }
}
