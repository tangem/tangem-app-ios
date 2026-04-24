//
//  NewsWidgetViewRedesign.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils
import TangemUI
import TangemLocalization

struct NewsWidgetViewRedesign: View {
    @ObservedObject var viewModel: NewsWidgetViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: MarketsWidgetLayout.Item.interItemSpacing) {
            header
                .disableAnimations()

            content
                .id(contentStateID)
                .transition(.opacity)
        }
        .animation(.easeInOut(duration: 0.3), value: contentStateID)
    }

    private var contentStateID: Int {
        switch viewModel.resultState {
        case .loading: return 0
        case .success: return 1
        case .failure: return 2
        }
    }

    // MARK: - Private Properties

    private var header: some View {
        MarketsCommonWidgetHeaderViewRedesign(
            headerTitle: Localization.commonNews,
            headerImage: Assets.Markets.tangemAI.image,
            buttonTitle: Localization.commonSeeAll,
            buttonAction: viewModel.handleAllNewsTap,
            isLoadingState: viewModel.headerLoadingState
        )
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.resultState {
        case .success(let state):
            makeSuccessContent(for: state)
        case .failure:
            makeErrorContent()
        case .loading:
            makeLoadingContent()
        }
    }

    func makeSuccessContent(for state: NewsWidgetViewModel.ResultState) -> some View {
        VStack(spacing: Layout.spacingBetweenSections) {
            if let trendingCardNewsItem = state.trendingCardNewsItem {
                TrendingCardNewsViewRedesign(itemState: .success(trendingCardNewsItem))
            }

            // Negative padding bleeds the carousel past the 16pt horizontal padding
            // that MarketsMainView applies to the entire widget container.
            CarouselNewsView(
                itemsState: .success(state.carouselNewsItems),
                onAllNewsTap: viewModel.handleCarouselAllNewsTap,
                onItemAppear: { index in
                    viewModel.handleCarouselItemAppear(at: index)
                }
            )
            .padding(.horizontal, -SizeUnit.x4.value)
        }
    }

    func makeErrorContent() -> some View {
        TangemUnableToLoadDataView(
            isButtonBusy: false,
            retryButtonAction: viewModel.tryLoadAgain
        )
        .padding(.vertical, 58)
        .infinityFrame(axis: .horizontal, alignment: .center)
    }

    func makeLoadingContent() -> some View {
        VStack(spacing: Layout.spacingBetweenSections) {
            TrendingCardNewsSkeletonView()

            MarketsCarouselNewsSkeletonView()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private extension NewsWidgetViewRedesign {
    enum Layout {
        static let spacingBetweenSections: CGFloat = .unit(.x3)
    }
}
