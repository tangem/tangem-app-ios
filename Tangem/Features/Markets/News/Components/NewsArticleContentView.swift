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
    let article: NewsArticleModel
    let onSourceTap: (NewsSource) -> Void
    let onShareTap: (() -> Void)?
    let bottomPadding: CGFloat
    let additionalContent: AdditionalContent

    init(
        article: NewsArticleModel,
        onSourceTap: @escaping (NewsSource) -> Void,
        onShareTap: (() -> Void)? = nil,
        bottomPadding: CGFloat = 32,
        @ViewBuilder additionalContent: () -> AdditionalContent = { EmptyView() }
    ) {
        self.article = article
        self.onSourceTap = onSourceTap
        self.onShareTap = onShareTap
        self.bottomPadding = bottomPadding
        self.additionalContent = additionalContent()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                NewsArticleHeaderView(article: article, onShareTap: onShareTap)
                    .padding(.top, 16)
                    .padding(.horizontal, 16)

                if !article.shortContent.isEmpty {
                    NewsQuickRecapView(content: article.shortContent)
                        .padding(.top, 32)
                        .padding(.horizontal, 16)
                }

                Text(article.content)
                    .style(Fonts.Regular.body, color: Color.Tangem.Text.Neutral.primary)
                    .padding(.top, 16)
                    .padding(.horizontal, 16)

                additionalContent
                    .padding(.horizontal, 16)

                if !article.sources.isEmpty {
                    NewsSourcesSectionView(sources: article.sources, onSourceTap: onSourceTap)
                        .padding(.top, 32)
                }
            }
            .padding(.bottom, bottomPadding)
        }
        .scrollIndicators(.hidden)
    }
}
