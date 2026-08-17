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
        VStack(spacing: 24) {
            navigationBar
                .padding(.horizontal, 16)
                .padding(.top, 12)

            VStack(spacing: 12) {
                NewsCategoryChipsView(
                    categories: viewModel.categories,
                    selectedCategoryId: $viewModel.selectedCategoryId
                )

                contentView
                    .overlay(alignment: .bottom) {
                        ListFooterOverlayShadowView(color: DesignSystem.Color.bgSecondary)
                            .frame(height: 100)
                            .allowsHitTesting(false)
                    }
            }
            .opacity(viewModel.overlayContentHidingProgress)
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .background(DesignSystem.Color.bgPrimary)
        .onFirstAppear { viewModel.handleViewAction(.onFirstAppear) }
        .onAppear { viewModel.handleViewAction(.onAppear) }
        .onOverlayContentProgressChange(overlayContentStateObserver: overlayContentStateObserver) { [weak viewModel] progress in
            viewModel?.onOverlayContentProgressChange(progress)
        }
        .injectMarketsNavigationConfigurator()
    }

    private var newsListBottomFadeOverlay: some View {
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

    private var navigationBar: some View {
        NavigationBar(
            title: Localization.commonNews,
            settings: .init(backgroundColor: DesignSystem.Color.bgPrimary),
            leftButtons: { navigationBarLeadingButton }
        )
        .environment(\.isRedesign, true)
    }

    @ViewBuilder
    private var navigationBarLeadingButton: some View {
        switch viewModel.presentSource {
        case .navigation:
            NavigationBarButton.back(action: {
                viewModel.handleViewAction(.back)
            })
        case .deeplink:
            NavigationBarButton.close(action: {
                viewModel.handleViewAction(.back)
            })
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
                    RedesignNewsSkeletonItemView()
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
        TangemUnableToLoadDataView(
            isButtonBusy: false,
            retryButtonAction: { viewModel.handleViewAction(.retry) }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 16)
    }
}

// MARK: - RedesignNewsSkeletonItemView

private struct RedesignNewsSkeletonItemView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: .zero) {
            Text(Constants.ratingPlaceholder)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                .skeletonable(isShown: true, cornerStyle: .capsule)

            FixedSpacer(height: 8)

            Text(Constants.titlePlaceholder)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .skeletonable(isShown: true, cornerStyle: .capsule)

            Spacer(minLength: 8)

            Text(Constants.timePlaceholder)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                .skeletonable(isShown: true, cornerStyle: .capsule)

            FixedSpacer(height: 8)

            HStack(spacing: 4) {
                ForEach(Constants.chipPlaceholders, id: \.self) { placeholder in
                    InfoChipView(
                        item: InfoChipItem(title: placeholder),
                        style: .redesign
                    )
                    .skeletonable(isShown: true, cornerStyle: .capsule)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .frame(height: Constants.cardHeight)
        .background(DesignSystem.Color.bgSecondary)
        .cornerRadiusContinuous(20)
    }

    private enum Constants {
        static let cardHeight: CGFloat = 152
        static let ratingPlaceholder = "----"
        static let titlePlaceholder = "-------------------------"
        static let timePlaceholder = "------"
        static let chipPlaceholders = ["----------", "-----", "---"]
    }
}
