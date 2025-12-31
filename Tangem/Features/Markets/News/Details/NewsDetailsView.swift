//
//  NewsDetailsView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct NewsDetailsView: View {
    @ObservedObject var viewModel: NewsDetailsViewModel

    var body: some View {
        VStack(spacing: 0) {
            navigationBar
            contentView
        }
        .background(Color.Tangem.Surface.level3.ignoresSafeArea())
        .onAppear { viewModel.handleViewAction(.onAppear) }
    }

    // MARK: - Navigation Bar

    private var navigationBar: some View {
        NavigationBar(
            title: "",
            settings: .init(backgroundColor: Color.Tangem.Surface.level3),
            leftButtons: {
                BackButton(
                    height: 44.0,
                    isVisible: true,
                    isEnabled: true,
                    hPadding: 10.0,
                    action: { viewModel.handleViewAction(.back) }
                )
            },
            rightButtons: {
                Button(action: { viewModel.handleViewAction(.share) }) {
                    Assets.share.image
                        .renderingMode(.template)
                        .foregroundColor(Color.Tangem.Graphic.Neutral.primary)
                        .frame(width: 44, height: 44)
                }
            }
        )
        .padding(.top, 12)
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
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

    private var loadingView: some View {
        NewsArticleSkeletonView()
    }

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
            bottomPadding: 56
        )
    }
}
