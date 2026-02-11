//
//  SwapMarketsTokensView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct SwapMarketsTokensView: View {
    @ObservedObject var viewModel: SwapMarketsTokensViewModel

    @Environment(\.mainWindowSize) private var mainWindowSize

    var body: some View {
        Group {
            switch viewModel.state {
            case .noResults:
                EmptyView()
            case .loading:
                sectionContent(isSearching: false, tokens: [], isLoading: true, isLoadingMore: false)
            case .loaded(let tokens, let isSearching, let isLoadingMore):
                sectionContent(isSearching: isSearching, tokens: tokens, isLoading: false, isLoadingMore: isLoadingMore)
            case .error:
                errorContent
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
    }

    @ViewBuilder
    private var errorContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(isSearching: false, count: 0)

            MarketsListErrorView(tryLoadAgain: viewModel.onRetry)
                .background(Colors.Background.action)
                .cornerRadiusContinuous(Constants.cornerRadius)
        }
    }

    @ViewBuilder
    private func sectionContent(
        isSearching: Bool,
        tokens: [MarketsItemViewModel],
        isLoading: Bool,
        isLoadingMore: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(isSearching: isSearching, count: tokens.count)

            Group {
                if isLoading {
                    loadingSkeletons
                } else {
                    VStack(spacing: 0) {
                        loadedTokens(tokens)

                        if isLoadingMore {
                            loadingMoreSkeletons
                        }
                    }
                }
            }
            .background(Colors.Background.action)
            .cornerRadiusContinuous(Constants.cornerRadius)
        }
    }

    private func sectionHeader(isSearching: Bool, count: Int) -> some View {
        HStack(spacing: Constants.titleCountSpacing) {
            Text(Localization.commonFeeSelectorOptionMarket)
                .style(Fonts.BoldStatic.title3, color: Colors.Text.primary1)

            if isSearching, count > 0 {
                Text("\(count)")
                    .style(Fonts.BoldStatic.title3, color: Colors.Text.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Constants.headerHorizontalPadding)
        .padding(.top, Constants.headerTopPadding)
        .padding(.bottom, Constants.headerBottomPadding)
    }

    private func loadedTokens(_ tokens: [MarketsItemViewModel]) -> some View {
        LazyVStack(spacing: 0) {
            ForEach(tokens) { item in
                MarketsItemView(viewModel: item, cellWidth: mainWindowSize.width)
            }
        }
    }

    private var loadingSkeletons: some View {
        VStack(spacing: 0) {
            ForEach(0 ..< Constants.skeletonItemsCount, id: \.self) { _ in
                MarketsSkeletonItemView()
            }
        }
    }

    private var loadingMoreSkeletons: some View {
        VStack(spacing: 0) {
            ForEach(0 ..< Constants.loadingMoreSkeletonItemsCount, id: \.self) { _ in
                MarketsSkeletonItemView()
            }
        }
    }
}

// MARK: - Constants

extension SwapMarketsTokensView {
    enum Constants {
        static let headerHorizontalPadding: CGFloat = 8
        static let headerTopPadding: CGFloat = 8
        static let headerBottomPadding: CGFloat = 14
        static let titleCountSpacing: CGFloat = 8
        static let cornerRadius: CGFloat = 14
        static let skeletonItemsCount: Int = 7
        static let loadingMoreSkeletonItemsCount: Int = 2
    }
}

// MARK: - SwapTokenSelectorEmptyContentView

/// A wrapper view that observes the markets view model state to conditionally show empty content.
/// This is needed because the empty content view needs to react to markets state changes.
struct SwapTokenSelectorEmptyContentView: View {
    var marketsTokensViewModel: SwapMarketsTokensViewModel?
    let message: String

    var body: some View {
        if let marketsViewModel = marketsTokensViewModel {
            // Observe markets state and hide empty message when markets has content
            SwapTokenSelectorEmptyContentViewObserver(
                marketsTokensViewModel: marketsViewModel,
                message: message
            )
        } else {
            // No markets view model - always show empty message
            AccountsAwareTokenSelectorEmptyContentView(message: message)
        }
    }
}

/// Internal view that observes the markets view model
private struct SwapTokenSelectorEmptyContentViewObserver: View {
    @ObservedObject var marketsTokensViewModel: SwapMarketsTokensViewModel
    let message: String

    var body: some View {
        // Don't show empty message if markets are loading or have results
        if !marketsTokensViewModel.hasVisibleContent {
            AccountsAwareTokenSelectorEmptyContentView(message: message)
        }
    }
}
