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

            content
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

    private var content: some View {
        VStack(spacing: Layout.spacingBetweenSections) {
            switch viewModel.resultState {
            case .success(let state):
                makeSuccessContent(for: state)
            case .failure:
                makeErrorContent()
            case .loading:
                makeLoadingContent()
            }
        }
        .padding(.horizontal, -SizeUnit.x4.value)
    }

    func makeSuccessContent(for state: NewsWidgetViewModel.ResultState) -> some View {
        VStack(spacing: Layout.spacingBetweenSections) {
            if let trendingCardNewsItem = state.trendingCardNewsItem {
                TrendingCardNewsViewRedesign(itemState: .success(trendingCardNewsItem))
            }

            CarouselNewsView(
                itemsState: .success(state.carouselNewsItems),
                onAllNewsTap: viewModel.handleCarouselAllNewsTap,
                onItemAppear: { index in
                    viewModel.handleCarouselItemAppear(at: index)
                }
            )
        }
    }

    func makeErrorContent() -> some View {
        TangemUnableToLoadDataView(
            isButtonBusy: false,
            retryButtonAction: viewModel.tryLoadAgain
        )
        .infinityFrame(axis: .horizontal, alignment: .center)
    }

    func makeLoadingContent() -> some View {
        VStack(spacing: Layout.spacingBetweenSections) {
            TrendingCardNewsViewRedesign(itemState: .loading)

            CarouselNewsView(
                itemsState: .loading,
                onAllNewsTap: viewModel.handleAllNewsTap
            )
        }
    }
}

private extension NewsWidgetViewRedesign {
    enum Layout {
        static let spacingBetweenSections: CGFloat = 12
    }
}
