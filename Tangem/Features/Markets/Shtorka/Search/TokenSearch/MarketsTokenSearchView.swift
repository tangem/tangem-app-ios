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
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: .unit(.x4)) {
                Color.clear
                    .frame(height: headerHeight)

                stateView
            }
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.immediately)
        .readGeometry(\.frame.height) { frameHeight = $0 }
    }
}

// MARK: - Subviews

private extension MarketsTokenSearchView {
    @ViewBuilder
    var stateView: some View {
        switch viewModel.state {
        case .idle:
            idleView
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

    var idleView: some View {
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
        case .idle:
            idleView
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
        if viewModel.isSearchEmpty {
            searchEmptyView
        } else {
            searchResultView
        }
    }

    var searchEmptyView: some View {
        Text(viewModel.searchEmptyTitle)
            .style(.Tangem.Subheadline.medium, color: .Tangem.Text.Neutral.tertiary)
            .frame(maxWidth: .infinity)
            .padding(.top, searchEmptyTopPadding)
    }

    var searchResultView: some View {
        VStack(spacing: portfolioMarketSpacing) {
            portfolioStateView
            marketView
        }
    }

    @ViewBuilder
    var portfolioStateView: some View {
        switch viewModel.portfolioState {
        case .idle:
            idleView
        case .empty:
            EmptyView()
        case .item(let item):
            portfolioView(item)
        }
    }

    func portfolioView(_ item: ViewModel.PortfolioItem) -> some View {
        sectionView(title: item.title) {
            MarketsPortfolioTokenSearchView(viewModel: item.model)
        }
    }

    @ViewBuilder
    var marketView: some View {
        switch viewModel.marketItem {
        case .some(let item): marketItemView(item)
        case .none: EmptyView()
        }
    }

    func marketItemView(_ item: ViewModel.MarketItem) -> some View {
        sectionView(title: item.title) {
            MarketsTokenSearchItemView(item: item)
        }
    }
}
