//
//  MarketsTokenSearchView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct MarketsTokenSearchView: View {
    typealias ViewModel = MarketsTokenSearchViewModel

    @State private var frameHeight: CGFloat = .zero

    @ScaledMetric private var portfolioMarketSpacing: CGFloat = .unit(.x10)
    @ScaledMetric private var sectionHeaderContentSpacing: CGFloat = .unit(.x5)
    @ScaledMetric private var headerLeadingPadding: CGFloat = .unit(.x2)

    @ObservedObject var viewModel: ViewModel

    let headerHeight: CGFloat

    private var searchEmptyTopPadding: CGFloat {
        frameHeight * 0.5 - headerHeight
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: .unit(.x4)) {
                Color.clear
                    .frame(height: headerHeight)

                stateView
            }
        }
        .readGeometry(\.frame.height) { frameHeight = $0 }
    }
}

// MARK: - Subviews

private extension MarketsTokenSearchView {
    @ViewBuilder
    var stateView: some View {
        switch viewModel.state {
        case .idle:
            emptyView
        case .recent:
            recentStateView
        case .search:
            searchStateView
        }
    }

    func sectionView<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: sectionHeaderContentSpacing) {
            Text(title)
                .style(.Tangem.Heading20.semibold, color: .Tangem.Text.Neutral.primary)
                .padding(.leading, headerLeadingPadding)

            content()
        }
    }

    var emptyView: some View {
        EmptyView()
    }
}

// MARK: - Recent state

private extension MarketsTokenSearchView {
    @ViewBuilder
    var recentStateView: some View {
        switch viewModel.recentState {
        case .item(let item):
            recentView(item)
        case .empty:
            recentEmptyView
        case .none:
            emptyView
        }
    }

    var recentEmptyView: some View {
        Color.Tangem.Surface.level2 // [REDACTED_TODO_COMMENT]
    }

    func recentView(_ item: ViewModel.RecentItem) -> some View {
        MarketsTokenSearchRecentsView(
            queries: item.queries,
            marketAssetViewModels: item.marketTokens,
            onQueryTap: item.onQuery,
            onClearAll: item.onClearAll
        )
    }
}

// MARK: - Search state

private extension MarketsTokenSearchView {
    @ViewBuilder
    var searchStateView: some View {
        switch viewModel.searchState {
        case .result(let portfolio, let market):
            searchResultView(portfolio: portfolio, market: market)
        case .empty(let item):
            searchEmptyView(item)
        case .none:
            emptyView
        }
    }

    func searchResultView(
        portfolio: ViewModel.PortfolioState,
        market: ViewModel.MarketState
    ) -> some View {
        VStack(spacing: portfolioMarketSpacing) {
            portfolioStateView(portfolio)
            marketStateView(market)
        }
    }

    func searchEmptyView(_ item: ViewModel.SearchEmptyItem) -> some View {
        Text(item.title)
            .style(.Tangem.Subheadline.medium, color: .Tangem.Text.Neutral.tertiary)
            .frame(maxWidth: .infinity)
            .padding(.top, searchEmptyTopPadding)
    }

    @ViewBuilder
    func portfolioStateView(_ state: ViewModel.PortfolioState) -> some View {
        switch state {
        case .empty:
            emptyView
        case .item(let item):
            portfolioView(item)
        }
    }

    func portfolioView(_ item: ViewModel.PortfolioItem) -> some View {
        let viewModel = MarketsPortfolioTokenSearchViewModel(
            walletModels: item.walletModels,
            onSingleToken: item.onSingleToken,
            onMultipleToken: item.onMultipleToken
        )
        return sectionView(title: item.title) {
            MarketsPortfolioTokenSearchView(viewModel: viewModel)
        }
    }

    @ViewBuilder
    func marketStateView(_ state: ViewModel.MarketState) -> some View {
        switch state {
        case .item(let item):
            marketView(item)
        case .loading:
            marketLoadingView()
        case .retry(let item):
            marketRetryView(item)
        case .empty:
            emptyView
        }
    }

    func marketView(_ item: ViewModel.MarketItem) -> some View {
        sectionView(title: item.title) {
            // [REDACTED_TODO_COMMENT]
        }
    }

    func marketLoadingView() -> some View {
        emptyView // [REDACTED_TODO_COMMENT]
    }

    func marketRetryView(_ item: ViewModel.MarketRetryItem) -> some View {
        emptyView // [REDACTED_TODO_COMMENT]
    }
}
