//
//  NewsArticleContentView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct NewsArticleContentView<AdditionalContent: View>: View {
    let article: NewsDetailsViewModel.ArticleViewModel
    let onSourceTap: (URL) -> Void
    let onShareTap: (() -> Void)?
    let bottomPadding: CGFloat
    @ViewBuilder let additionalContent: () -> AdditionalContent

    init(
        article: NewsDetailsViewModel.ArticleViewModel,
        onSourceTap: @escaping (URL) -> Void,
        onShareTap: (() -> Void)? = nil,
        bottomPadding: CGFloat = 32,
        @ViewBuilder additionalContent: @escaping () -> AdditionalContent = { EmptyView() }
    ) {
        self.article = article
        self.onSourceTap = onSourceTap
        self.onShareTap = onShareTap
        self.bottomPadding = bottomPadding
        self.additionalContent = additionalContent
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                NewsArticleHeaderView(article: article, onShareTap: onShareTap)
                    .padding(.top, 16)

                if !article.shortContent.isEmpty {
                    NewsQuickRecapView(content: article.shortContent)
                        .padding(.top, 32)
                }

                Text(article.content)
                    .style(Fonts.Regular.body, color: Color.Tangem.Text.Neutral.primary)
                    .padding(.top, 16)

                additionalContent()

                if !article.sources.isEmpty {
                    NewsSourcesSectionView(sources: article.sources, onSourceTap: onSourceTap)
                        .padding(.top, 32)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, bottomPadding)
        }
    }
}
