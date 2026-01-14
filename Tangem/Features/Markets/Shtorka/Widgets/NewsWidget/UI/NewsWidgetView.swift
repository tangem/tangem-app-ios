//
//  NewsWidgetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils
import TangemUI
import TangemLocalization

struct NewsWidgetView: View {
    @ObservedObject var viewModel: NewsWidgetViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: MarketsWidgetLayout.Item.interItemSpacing) {
            header

            content
        }
        .infinityFrame(axis: .horizontal)
    }

    // MARK: - Private Properties

    private var header: some View {
        MarketsCommonWidgetHeaderView(
            headerTitle: Localization.commonNews,
            headerImage: Assets.Markets.tangemAI.image,
            buttonTitle: Localization.commonSeeAll,
            buttonAction: viewModel.handleAllNewsTap,
            isLoading: viewModel.resultState.isLoading
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
    }

    func makeSuccessContent(for state: NewsWidgetViewModel.ResultState) -> some View {
        VStack(spacing: Layout.spacingBetweenSections) {
            if let trendingCardNewsItem = state.trendingCardNewsItem {
                TrendingCardNewsView(itemState: .success(trendingCardNewsItem))
            }

            CarouselNewsView(
                itemsState: .success(state.carouselNewsItems),
                onAllNewsTap: viewModel.handleAllNewsTap
            )
        }
    }

    func makeErrorContent() -> some View {
        MarketsWidgetErrorView(tryLoadAgain: viewModel.tryLoadAgain)
    }

    func makeLoadingContent() -> some View {
        VStack(spacing: Layout.spacingBetweenSections) {
            TrendingCardNewsView(itemState: .loading)

            CarouselNewsView(
                itemsState: .loading,
                onAllNewsTap: viewModel.handleAllNewsTap
            )
        }
    }
}

private extension NewsWidgetView {
    enum Layout {
        static let spacingBetweenSections: CGFloat = 12
    }
}
