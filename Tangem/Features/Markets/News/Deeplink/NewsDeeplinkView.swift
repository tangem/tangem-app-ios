//
//  NewsDeeplinkView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct NewsDeeplinkView: View {
    @ObservedObject var viewModel: NewsDetailsViewModel

    var body: some View {
        content
            .background(Color.Tangem.Surface.level3.ignoresSafeArea())
            .onAppear { viewModel.handleViewAction(.onAppear) }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { viewModel.handleViewAction(.share) }) {
                        Assets.share.image
                            .renderingMode(.template)
                            .foregroundColor(Color.Tangem.Graphic.Neutral.primary)
                    }
                }
            }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch viewModel.loadingState {
        case .loading:
            loadingView
        case .error:
            errorView
        case .loaded:
            if let article = viewModel.article {
                articleContent(article)
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        NewsArticleSkeletonView()
    }

    // MARK: - Error View

    private var errorView: some View {
        UnableToLoadDataView(
            isButtonBusy: false,
            retryButtonAction: { viewModel.handleViewAction(.retry) }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 16)
    }

    // MARK: - Article Content

    private func articleContent(_ article: NewsDetailsViewModel.ArticleViewModel) -> some View {
        NewsArticleContentView(
            article: article,
            onSourceTap: { url in viewModel.handleViewAction(.openSource(url)) },
            bottomPadding: 32
        ) {
            if !article.relatedTokens.isEmpty {
                relatedTokensSection(article.relatedTokens)
                    .padding(.top, 24)
            }
        }
    }

    // MARK: - Related Tokens Section (Static)

    private func relatedTokensSection(_ tokens: [NewsDetailsViewModel.RelatedToken]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Localization.newsRelatedTokens)
                .style(Fonts.Bold.title3, color: Color.Tangem.Text.Neutral.primary)

            VStack(spacing: 0) {
                ForEach(tokens) { token in
                    relatedTokenRow(token)

                    if token.id != tokens.last?.id {
                        Divider()
                            .padding(.leading, 62)
                    }
                }
            }
            .background(Color.Tangem.Surface.level4)
            .cornerRadius(14)
        }
    }

    private func relatedTokenRow(_ token: NewsDetailsViewModel.RelatedToken) -> some View {
        HStack(spacing: 12) {
            IconView(url: token.iconURL, size: CGSize(bothDimensions: 36), forceKingfisher: true)

            VStack(alignment: .leading, spacing: 4) {
                Text(token.name)
                    .style(Fonts.Bold.subheadline, color: Color.Tangem.Text.Neutral.primary)
                    .lineLimit(1)

                Text(token.symbol)
                    .style(Fonts.Regular.caption1, color: Color.Tangem.Text.Neutral.tertiary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}
