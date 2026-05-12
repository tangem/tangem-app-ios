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
        if FeatureProvider.isAvailable(.redesign) {
            redesignContent
        } else {
            legacyContent
        }
    }

    // MARK: - Redesign

    private var redesignContent: some View {
        VStack(alignment: .leading, spacing: .unit(.x4)) {
            scoreAndTimeLine

            Text(article.title)
                .style(.Tangem.Heading28.regular, color: .Tangem.Text.Neutral.primary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, .unit(.x1))
        .padding(.vertical, .unit(.x1_5))
    }

    private var scoreAndTimeLine: some View {
        HStack(spacing: .unit(.x2)) {
            HStack(spacing: .unit(.x2)) {
                NewsRatingViewRedesign(
                    rating: article.score,
                    isHighlighted: true,
                    spacing: .unit(.x2)
                )
            }

            Text("•")
                .style(.Tangem.Body16.medium, color: .Tangem.Text.Neutral.tertiary)

            HStack(spacing: .unit(.x2)) {
                Assets.Glyphs.calendar.image
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                    .foregroundStyle(Color.Tangem.Graphic.Neutral.secondary)

                Text(article.relativeTime)
                    .style(.Tangem.Body16.medium, color: .Tangem.Text.Neutral.secondary)
            }
        }
    }

    // MARK: - Legacy

    private var legacyContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
                NewsScoreBadgeView(score: article.score)

                Text(AppConstants.dotSign)

                Text(article.relativeTime)

                if let onShareTap {
                    Spacer()

                    Button(action: onShareTap) {
                        Assets.share.image
                            .renderingMode(.template)
                            .foregroundColor(Color.Tangem.Graphic.Neutral.primary)
                    }
                }
            }
            .style(Fonts.Bold.subheadline, color: Color.Tangem.Text.Neutral.secondary)
            .padding(.bottom, 8)

            Text(article.title)
                .style(Fonts.Bold.title1, color: Color.Tangem.Text.Neutral.primary)
                .multilineTextAlignment(.leading)

            if article.categories.isNotEmpty || article.relatedTokens.isNotEmpty {
                tagsSection
                    .padding(.top, 20)
            }
        }
    }

    private var tagsSection: some View {
        let chips = article.categories.map { InfoChipItem(id: String($0.id), title: $0.name) }
            + article.relatedTokens.map { InfoChipItem(id: $0.id, title: $0.symbol, leadingIcon: .url($0.iconURL)) }
        return InfoChipsRowView(chips: chips, lineLimit: nil)
    }
}
