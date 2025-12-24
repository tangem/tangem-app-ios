//
//  NewsListView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct NewsListView: View {
    @ObservedObject var viewModel: NewsListViewModel

    var body: some View {
        VStack(spacing: 12) {
            // Header
            NavigationBar(
                title: "News",
                leftButtons: {
                    BackButton(
                        height: 44.0,
                        isVisible: true,
                        isEnabled: true,
                        hPadding: 10.0,
                        action: { viewModel.handleViewAction(.back) }
                    )
                }
            )
            .padding(.top, 12)

            // Category filter chips
            NewsCategoryChipsView(
                categories: viewModel.categories,
                selectedCategoryId: $viewModel.selectedCategoryId
            )

            // Content
            contentView
        }
        .background(Color.Tangem.Surface.level3.ignoresSafeArea())
        .onAppear { viewModel.handleViewAction(.onAppear) }
    }

    @ViewBuilder
    private var contentView: some View {
        switch viewModel.loadingState {
        case .loading:
            loadingSkeletons
        case .error:
            errorView
        case .noResults:
            noResultsView
        case .loaded, .paginationLoading, .paginationError, .allDataLoaded, .idle:
            newsList
        }
    }

    private var newsList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.newsItems) { item in
                    NewsItemView(viewModel: item)
                }

                paginationFooter
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    @ViewBuilder
    private var paginationFooter: some View {
        switch viewModel.loadingState {
        case .loaded:
            // Trigger pagination when this spacer appears
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

    private var noResultsView: some View {
        Text("No news found")
            .style(Fonts.Bold.caption1, color: Colors.Text.tertiary)
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
        .background(Colors.Background.action)
        .cornerRadius(14)
    }
}
