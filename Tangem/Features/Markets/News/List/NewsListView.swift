//
//  NewsListView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemFoundation

struct NewsListView: View {
    @ObservedObject var viewModel: NewsListViewModel

    @Injected(\.overlayContentStateObserver) private var overlayContentStateObserver: OverlayContentStateObserver

    var body: some View {
        VStack(spacing: 12) {
            NavigationBar(
                title: Localization.commonNews,
                settings: .init(backgroundColor: Color.Tangem.Surface.level2),
                leftButtons: {
                    MarketsNavigationBackButton(
                        presentSource: viewModel.presentSource,
                        action: { viewModel.handleViewAction(.back) }
                    )
                }
            )
            .padding(.top, 12)

            Group {
                NewsCategoryChipsView(
                    categories: viewModel.categories,
                    selectedCategoryId: $viewModel.selectedCategoryId
                )

                contentView
            }
            .opacity(viewModel.overlayContentHidingProgress)
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .background(Color.Tangem.Surface.level2)
        .onFirstAppear { viewModel.handleViewAction(.onFirstAppear) }
        .onAppear { viewModel.handleViewAction(.onAppear) }
        .onOverlayContentProgressChange(overlayContentStateObserver: overlayContentStateObserver) { [weak viewModel] progress in
            viewModel?.onOverlayContentProgressChange(progress)
        }
        .injectMarketsNavigationConfigurator()
    }

    private var newsListBottomFadeOverlay: some View {
        BottomFadeWithBlur(backgroundColor: Color.Tangem.Surface.level2)
            .allowsHitTesting(false)
    }

    @ViewBuilder
    private var contentView: some View {
        switch viewModel.loadingState {
        case .loading:
            loadingSkeletons
        case .error:
            errorView
        case .loaded, .paginationLoading, .paginationError, .allDataLoaded, .idle, .noResults:
            newsList
        }
    }

    private var newsList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.newsItems) { item in
                    NewsItemView(viewModel: item) {
                        viewModel.handleViewAction(.onNewsSelected(item.id))
                    }
                }

                paginationFooter
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .safeAreaInset(edge: .bottom) {
            newsListBottomFadeOverlay
        }
    }

    @ViewBuilder
    private var paginationFooter: some View {
        switch viewModel.loadingState {
        case .loaded:
            Color.clear
                .frame(height: 1)
                .onAppear {
                    viewModel.handleViewAction(.loadMore)
                }
        case .paginationLoading:
            loadingIndicator
        case .paginationError:
            paginationErrorView
        case .allDataLoaded:
            EmptyView()
        default:
            EmptyView()
        }
    }

    private var paginationErrorView: some View {
        UnableToLoadDataView(
            isButtonBusy: false,
            retryButtonAction: { viewModel.handleViewAction(.loadMore) }
        )
        .padding(.vertical, 16)
    }

    private var loadingSkeletons: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 12) {
                ForEach(0 ..< 10, id: \.self) { _ in
                    NewsSkeletonItemView()
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var loadingIndicator: some View {
        HStack {
            Spacer()
            ProgressView()
                .padding()
            Spacer()
        }
    }

    private var errorView: some View {
        UnableToLoadDataView(
            isButtonBusy: false,
            retryButtonAction: { viewModel.handleViewAction(.retry) }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 16)
    }
}

// MARK: - NewsSkeletonItemView

private struct NewsSkeletonItemView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Score + Category skeleton
            HStack(spacing: 4) {
                SkeletonView()
                    .frame(width: 50, height: 14)
                    .cornerRadius(4)

                SkeletonView()
                    .frame(width: 60, height: 14)
                    .cornerRadius(4)
            }

            // Title skeleton (2 lines)
            SkeletonView()
                .frame(height: 18)
                .cornerRadius(4)

            SkeletonView()
                .frame(width: 200, height: 18)
                .cornerRadius(4)

            // Time skeleton
            SkeletonView()
                .frame(width: 60, height: 14)
                .cornerRadius(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.Tangem.Surface.level3)
        .cornerRadius(14)
    }
}
