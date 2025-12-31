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

struct NewsPagerView: View {
    @ObservedObject var viewModel: NewsPagerViewModel
    let isDeeplinkMode: Bool

    init(viewModel: NewsPagerViewModel, isDeeplinkMode: Bool = false) {
        self.viewModel = viewModel
        self.isDeeplinkMode = isDeeplinkMode
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                if !isDeeplinkMode {
                    navigationBar
                }
                pagerContent
            }

            if !isDeeplinkMode, viewModel.newsIds.count > 1 {
                pageIndicatorOverlay
                    .ignoresSafeArea(.container, edges: .bottom)

                PageIndicatorView(
                    totalPages: viewModel.newsIds.count,
                    currentIndex: viewModel.currentIndex
                )
                .padding(.bottom, 8)
            }
        }
        .background(Color.Tangem.Surface.level3.ignoresSafeArea())
        .onAppear { viewModel.handleViewAction(.onAppear) }
        .if(isDeeplinkMode) { view in
            view.toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { viewModel.handleViewAction(.share) }) {
                        Assets.Glyphs.moreVertical.image
                            .foregroundColor(Color.Tangem.Graphic.Neutral.primary)
                    }
                }
            }
        }
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
                        .foregroundColor(Color.Tangem.Graphic.Neutral.primary)
                        .padding(.trailing, 16)
                }
            }
        )
        .padding(.top, 12)
    }

    // MARK: - Pager Content

    private var currentIndexBinding: Binding<Int> {
        Binding(
            get: { viewModel.currentIndex },
            set: { newIndex in
                guard newIndex >= 0, newIndex < viewModel.newsIds.count else { return }
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

    private var state: NewsPagerViewModel.ArticleState {
        viewModel.articleState(for: newsId)
    }

    private var isLoading: Bool {
        state == .loading
    }

    private var article: NewsDetailsViewModel.ArticleViewModel {
        if case .loaded(let article) = state {
            return article
        }
        return .placeholder
    }

    private var isError: Bool {
        state == .error
    }

    var body: some View {
        ZStack {
            articleContentView(article)
                .allowsHitTesting(!isLoading && !isError)
                .skeletonable(isShown: isLoading, radius: 14)

            // Error overlay - use hidden() to maintain structural identity
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

    private func articleContentView(_ article: NewsDetailsViewModel.ArticleViewModel) -> some View {
        NewsArticleContentView(
            article: article,
            onSourceTap: { url in viewModel.handleViewAction(.openSource(url)) },
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
        let likeState = viewModel.likeState(for: newsId)

        return Button { viewModel.handleViewAction(.like(newsId)) } label: {
            HStack(spacing: 8) {
                ZStack {
                    Assets.Glyphs.favorite.image
                        .foregroundStyle(Color.Tangem.Text.Neutral.primary)

                    if likeState.isLiked {
                        Assets.Glyphs.favouriteFill.image
                            .transition(.scaleOpacity.animation(.easeInOut(duration: 0.2)))
                    }
                }

                Text(Localization.newsLike)
                    .style(Fonts.Bold.subheadline, color: Color.Tangem.Text.Neutral.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.Tangem.Surface.level4)
            .cornerRadius(20)
            .opacity(likeState.isLoading ? 0.5 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .frame(maxWidth: .infinity, alignment: .leading)
        .disabled(likeState.isLoading)
    }
}
