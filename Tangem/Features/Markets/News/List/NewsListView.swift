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
import TangemUIUtils
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

            VStack(spacing: 12) {
                NewsCategoryChipsView(
                    categories: viewModel.categories,
                    selectedCategoryId: $viewModel.selectedCategoryId
                )

                contentView
                    .overlay(alignment: .bottom) {
                        ListFooterOverlayShadowView(color: Color.Tangem.Surface.level3)
                            .frame(height: 100)
                            .allowsHitTesting(false)
                    }
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
                    if FeatureProvider.isAvailable(.redesign) {
                        RedesignNewsSkeletonItemView()
                    } else {
                        NewsSkeletonItemView()
                    }
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

    @ViewBuilder
    private var errorView: some View {
        if FeatureProvider.isAvailable(.redesign) {
            TangemUnableToLoadDataView(
                isButtonBusy: false,
                retryButtonAction: { viewModel.handleViewAction(.retry) }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 16)
        } else {
            UnableToLoadDataView(
                isButtonBusy: false,
                retryButtonAction: { viewModel.handleViewAction(.retry) }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 16)
        }
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

// MARK: - RedesignNewsSkeletonItemView

private struct RedesignNewsSkeletonItemView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: .zero) {
            Text(Constants.ratingPlaceholder)
                .style(.Tangem.Caption12.semibold, color: .Tangem.Text.Neutral.secondary)
                .skeletonable(isShown: true, cornerStyle: .capsule)

            FixedSpacer(height: .unit(.x2))

            Text(Constants.titlePlaceholder)
                .style(.Tangem.Body16.regular, color: .Tangem.Text.Neutral.primary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .skeletonable(isShown: true, cornerStyle: .capsule)

            Spacer(minLength: .unit(.x2))

            Text(Constants.timePlaceholder)
                .style(.Tangem.Caption12.semibold, color: .Tangem.Text.Neutral.secondary)
                .skeletonable(isShown: true, cornerStyle: .capsule)

            FixedSpacer(height: .unit(.x2))

            HStack(spacing: .unit(.x1)) {
                ForEach(Constants.chipPlaceholders, id: \.self) { placeholder in
                    InfoChipView(
                        item: InfoChipItem(title: placeholder),
                        style: .redesign
                    )
                    .skeletonable(isShown: true, cornerStyle: .capsule)
                }
            }
        }
        .padding(.unit(.x4))
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .frame(height: Constants.cardHeight)
        .background(Color.Tangem.Surface.level3)
        .cornerRadiusContinuous(.unit(.x5))
    }

    private enum Constants {
        static let cardHeight: CGFloat = 152
        static let ratingPlaceholder = "----"
        static let titlePlaceholder = "-------------------------"
        static let timePlaceholder = "------"
        static let chipPlaceholders = ["----------", "-----", "---"]
    }
}
