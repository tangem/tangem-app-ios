//
//  NewsPagerView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils
import TangemFoundation

struct NewsPagerView: View {
    @ObservedObject var viewModel: NewsPagerViewModel

    @Injected(\.overlayContentStateObserver) private var overlayContentStateObserver: OverlayContentStateObserver

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                if viewModel.shouldShowNavigationBar {
                    navigationBar
                }

                pagerContent
                    .opacity(viewModel.overlayContentHidingProgress)
            }

            if viewModel.shouldShowPageIndicator {
                Group {
                    pageIndicatorOverlay
                        .ignoresSafeArea(.container, edges: .bottom)
                    PageIndicatorView(
                        totalPages: viewModel.newsIds.count,
                        currentIndex: viewModel.currentIndex
                    )
                    .padding(.bottom, 8)
                }
                .opacity(viewModel.overlayContentHidingProgress)
            }
        }
        .background(Color.Tangem.Surface.level3.ignoresSafeArea())
        .onAppear { viewModel.handleViewAction(.onAppear) }
        .onOverlayContentProgressChange(overlayContentStateObserver: overlayContentStateObserver) { [weak viewModel] progress in
            viewModel?.onOverlayContentProgressChange(progress)
        }
        .if(viewModel.isDeeplinkMode) { view in
            view.toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { viewModel.handleViewAction(.share) }) {
                        Assets.Glyphs.moreVertical.image
                            .foregroundColor(shareButtonColor)
                    }
                    .disabled(viewModel.isCurrentArticleLoading)
                }
            }
        }
        .injectMarketsNavigationControllerConfigurator()
    }

    private var pageIndicatorOverlay: some View {
        ZStack(alignment: .bottom) {
            VStack {
                Spacer()
                LinearGradient(
                    colors: [
                        Color.Tangem.Surface.level3.opacity(0),
                        Color.Tangem.Surface.level3,
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 200)
                .ignoresSafeArea(.container, edges: .bottom)
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Navigation Bar

    private var shareButtonColor: Color {
        viewModel.isCurrentArticleLoading
            ? Color.Tangem.Graphic.Neutral.tertiary
            : Color.Tangem.Graphic.Neutral.primary
    }

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
                    Assets.Glyphs.moreVertical.image
                        .foregroundColor(shareButtonColor)
                        .padding(.trailing, 16)
                }
                .disabled(viewModel.isCurrentArticleLoading)
            }
        )
        .padding(.top, 12)
    }

    // MARK: - Pager Content

    private var currentIndexBinding: Binding<Int> {
        Binding(
            get: { viewModel.currentIndex },
            set: { newIndex in
                guard viewModel.isValidIndex(newIndex) else { return }
                // Defer state update to let TabView animation complete
                DispatchQueue.main.async {
                    viewModel.handleViewAction(.pageChanged(newIndex))
                }
            }
        )
    }

    private var pagerContent: some View {
        TabView(selection: currentIndexBinding) {
            ForEach(Array(viewModel.newsIds.enumerated()), id: \.element) { index, newsId in
                NewsPageContentView(newsId: newsId, viewModel: viewModel)
                    .tag(index)
                    .contentShape(Rectangle())
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea(.container, edges: .bottom)
        .id(viewModel.newsIds.count)
    }
}

// MARK: - NewsPageContentView

private struct NewsPageContentView: View {
    let newsId: Int
    @ObservedObject var viewModel: NewsPagerViewModel

    var body: some View {
        let isLoading = viewModel.isLoading(for: newsId)
        let isError = viewModel.isError(for: newsId)
        let article = viewModel.article(for: newsId)

        ZStack {
            articleContentView(article)
                .allowsHitTesting(!isLoading && !isError)
                .hidden(isLoading)

            NewsArticleSkeletonView()
                .hidden(!isLoading)

            UnableToLoadDataView(
                isButtonBusy: false,
                retryButtonAction: { viewModel.handleViewAction(.retry) }
            )
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.Tangem.Surface.level3)
            .hidden(!isError)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Article Content

    private func articleContentView(_ article: NewsDetailsViewModel.ArticleModel) -> some View {
        NewsArticleContentView(
            article: article,
            onSourceTap: { source in viewModel.handleViewAction(.openSource(source)) },
            bottomPadding: 54
        ) {
            likeButton(for: article.id)
                .padding(.top, 24)

            if !article.relatedTokens.isEmpty {
                RelatedTokensSectionView(viewModel: viewModel.relatedTokensViewModel(for: article))
                    .padding(.top, 32)
            }
        }
    }

    // MARK: - Like Button

    private func likeButton(for newsId: Int) -> some View {
        let isLiked = viewModel.isLiked(for: newsId)

        return Button { viewModel.handleViewAction(.like(newsId)) } label: {
            HStack(spacing: 8) {
                ZStack {
                    Assets.Glyphs.glyphsFavorite.image
                        .frame(size: .init(bothDimensions: 22))
                        .foregroundStyle(Color.Tangem.Text.Neutral.primary)

                    if isLiked {
                        Assets.Glyphs.glyphsFavouriteFill.image
                            .resizable()
                            .frame(size: .init(bothDimensions: 22))
                            .transition(.scale.animation(.easeInOut(duration: 0.2)))
                    }
                }

                Text(Localization.newsLike)
                    .style(Fonts.Bold.subheadline, color: Color.Tangem.Text.Neutral.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.Tangem.Surface.level4)
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
