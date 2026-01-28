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

struct NewsArticleHeaderView: View {
    let article: NewsDetailsViewModel.ArticleModel
    var onShareTap: (() -> Void)?

    var body: some View {
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
        return InfoChipsRowView(chips: chips)
    }
}
