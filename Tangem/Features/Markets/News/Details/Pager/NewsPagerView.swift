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

    @Environment(\.mainShtorkaSize) private var sheetSize

    @State private var sheetNavigationBarHeight: CGFloat = 0

    @Injected(\.overlayContentStateObserver) private var overlayContentStateObserver: OverlayContentStateObserver

    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    if !sheetSize.isFeedSheet, !viewModel.isNativeNavigationBarUsed {
                        navigationBar
                    }

                    pagerContent
                        .opacity(sheetSize.isFeedSheet ? 1 : viewModel.overlayContentHidingProgress)
                        .hiddenWhileCollapsed()
                }

                if sheetSize.isFeedSheet {
                    sheetNavigationBar
                        .readGeometry(\.size.height, bindTo: $sheetNavigationBarHeight)
                }
            }

            if viewModel.shouldShowPageIndicator, !sheetSize.isNonFullFeedSheet {
                Group {
                    pageIndicatorOverlay
                        .ignoresSafeArea(.container, edges: .bottom)
                    pageIndicator
                        .padding(.bottom, 8)
                }
                .opacity(sheetSize.isFeedSheet ? 1 : viewModel.overlayContentHidingProgress)
            }
        }
        .background(backgroundColor.ignoresSafeArea())
        .onAppear { viewModel.handleViewAction(.onAppear) }
        .onOverlayContentProgressChange(overlayContentStateObserver: overlayContentStateObserver) { [weak viewModel] progress in
            viewModel?.onOverlayContentProgressChange(progress)
        }
        .if(!sheetSize.isFeedSheet && (viewModel.isMarketsSheetFlow || viewModel.isDeeplinkMode)) { view in
            view.injectMarketsNavigationConfigurator(isSimplified: viewModel.isDeeplinkMode)
        }
        .if(sheetSize.isFeedSheet) { view in
            view
                .toolbar(.hidden, for: .navigationBar)
                .background(FeedPopGestureEnabler(prioritizesNavigation: true))
        }
        .if(!sheetSize.isFeedSheet && viewModel.isNativeNavigationBarUsed) { view in
            view
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    trailingToolbarContent
                }
        }
    }

    private var pageIndicator: some View {
        PageIndicatorViewRedesign(
            totalPages: viewModel.newsIds.count,
            currentIndex: viewModel.currentIndex
        )
    }

    private var pageIndicatorOverlay: some View {
        redesignPageIndicatorOverlay
    }

    private var redesignPageIndicatorOverlay: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: .zero) {
                Spacer()
                LinearGradient(
                    colors: [
                        DesignSystem.Color.bgPrimary.opacity(0),
                        DesignSystem.Color.bgPrimary,
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

    private var sheetNavigationBar: some View {
        NavigationHeader(
            leadingContent: {
                if viewModel.isDeeplinkMode {
                    NavigationBarButton.close(action: { viewModel.handleViewAction(.back) })
                        .redesigned()
                } else {
                    NavigationBarButton.back(action: { viewModel.handleViewAction(.back) })
                        .redesigned()
                }
            },
            principalContent: {
                if sheetSize.isCollapsedFeedSheet {
                    Text(viewModel.currentArticle?.title ?? Localization.commonNews)
                        .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                        .lineLimit(1)
                }
            },
            trailingContent: {
                NavigationBarButton.share(action: { viewModel.handleViewAction(.share) })
                    .redesigned()
                    .disabled(viewModel.isCurrentArticleLoading)
            }
        )
    }

    private var navigationBar: some View {
        NavigationBar(
            title: "",
            settings: .init(backgroundColor: DesignSystem.Color.bgPrimary),
            leftButtons: {
                Group {
                    if viewModel.isDeeplinkMode {
                        NavigationBarButton.close(action: { viewModel.handleViewAction(.back) })
                    } else {
                        NavigationBarButton.back(action: { viewModel.handleViewAction(.back) })
                    }
                }
                .redesigned()
                .padding(.leading, 16)
            },
            rightButtons: {
                NavigationBarButton.share(action: { viewModel.handleViewAction(.share) })
                    .redesigned()
                    .disabled(viewModel.isCurrentArticleLoading)
                    .padding(.trailing, 16)
            }
        )
        .padding(.top, 12)
    }

    private var backgroundColor: Color {
        !sheetSize.isNonFullFeedSheet ? DesignSystem.Color.bgPrimary : .clear
    }

    @ToolbarContentBuilder
    private var trailingToolbarContent: some ToolbarContent {
        NavigationToolbarButton.share(placement: .topBarTrailing) {
            viewModel.handleViewAction(.share)
        }
        .redesigned()
        .customizationBehavior(viewModel.isCurrentArticleLoading ? .disabled : .default)
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
                    .if(sheetSize.isFeedSheet) { view in
                        view.safeAreaInset(edge: .top, spacing: 0) {
                            Color.clear.frame(height: sheetNavigationBarHeight)
                        }
                    }
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

            errorView
                .hidden(!isError)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var errorView: some View {
        TangemUnableToLoadDataView(
            isButtonBusy: false,
            retryButtonAction: { viewModel.handleViewAction(.retry) }
        )
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Color.bgPrimary)
    }

    // MARK: - Article Content

    private func articleContentView(_ article: NewsArticleModel) -> some View {
        NewsArticleContentView(
            article: article,
            onSourceTap: { source in viewModel.handleViewAction(.openSource(source)) },
            bottomPadding: viewModel.isNativeNavigationBarUsed ? 70 : 54
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
        redesignLikeButton(for: newsId)
    }

    private func redesignLikeButton(for newsId: Int) -> some View {
        let isLiked = viewModel.isLiked(for: newsId)

        return SwiftUI.Button { viewModel.handleViewAction(.like(newsId)) } label: {
            HStack(spacing: 4) {
                ZStack {
                    if isLiked {
                        Assets.Glyphs.glyphsFavouriteFill.image
                            .resizable()
                            .frame(size: .init(bothDimensions: 20))
                            .foregroundStyle(DesignSystem.Color.iconAccentRed)
                            .transition(.scale.animation(.easeInOut(duration: 0.2)))
                    } else {
                        Assets.Glyphs.glyphsFavorite.image
                            .resizable()
                            .frame(size: .init(bothDimensions: 20))
                            .foregroundStyle(DesignSystem.Color.iconPrimary)
                            .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                    }
                }

                Text(Localization.newsLike)
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
            }
            .padding(.horizontal, 12)
            .frame(height: 36)
            .frame(minWidth: 46)
            .background(DesignSystem.Color.bgOpaquePrimary, in: .capsule)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
