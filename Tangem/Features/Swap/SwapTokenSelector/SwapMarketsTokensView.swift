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
        switch viewModel.state {
        case .noResults:
            EmptyView()
                .onAppear {
                    viewModel.onAppear()
                }
        case .loading:
            sectionContent(isSearching: false, tokens: [], isLoading: true, isLoadingMore: false)
                .onAppear {
                    viewModel.onAppear()
                }
        case .loaded(let tokens, let isSearching, let isLoadingMore):
            sectionContent(isSearching: isSearching, tokens: tokens, isLoading: false, isLoadingMore: isLoadingMore)
                .onAppear {
                    viewModel.onAppear()
                }
        case .error:
            errorContent
                .onAppear {
                    viewModel.onAppear()
                }
        }
    }

    private var errorContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(isSearching: false, count: 0)

            MarketsListErrorView(tryLoadAgain: viewModel.onRetry)
                .cornerRadiusContinuous(Constants.cornerRadius)
        }
    }

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
            Text(Localization.marketsCommonTitle)
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

struct SwapTokenSelectorEmptyContentView: View {
    @ObservedObject var tokenSelectorViewModel: TokenSelectorViewModel
    var marketsTokensViewModel: SwapMarketsTokensViewModel?
    let message: String

    var body: some View {
        switch emptyReason {
        case .filteredOut:
            SwapSourceFilteredOutEmptyView(action: tokenSelectorViewModel.resetBalanceFilter)
        case .noTokens, .none:
            defaultEmptyContent
        }
    }

    private var emptyReason: TokenSelectorEmptyReason? {
        if case .empty(let reason) = tokenSelectorViewModel.contentVisibility {
            return reason
        }

        return nil
    }

    @ViewBuilder
    private var defaultEmptyContent: some View {
        if let marketsViewModel = marketsTokensViewModel {
            // Observe markets state and hide empty message when markets has content
            SwapTokenSelectorEmptyContentViewObserver(
                marketsTokensViewModel: marketsViewModel,
                message: message
            )
        } else {
            // No markets view model - always show empty message
            TokenSelectorEmptyContentView(message: message)
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
            TokenSelectorEmptyContentView(message: message)
        }
    }
}

private struct SwapSourceFilteredOutEmptyView: View {
    let action: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                icon

                Text(Localization.swapTokenSelectorEmptyFilteredMessage)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.tertiary)
                    .multilineTextAlignment(.center)
            }

            TangemButton(
                content: .text(AttributedString(Localization.commonSeeAll)),
                action: action
            )
            .setStyleType(.secondary)
            .setSize(.x9)
            .fixedSize(horizontal: true, vertical: false)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 48)
        .padding(.vertical, 24)
        .background(Colors.Background.action)
        .cornerRadiusContinuous(SwapMarketsTokensView.Constants.cornerRadius)
    }

    private var icon: some View {
        Assets.infoCircle20.image
            .renderingMode(.template)
            .resizable()
            .frame(width: 20, height: 20)
            .foregroundStyle(DesignSystem.Color.iconSecondary)
            .frame(width: 40, height: 40)
            .background(DesignSystem.Color.bgOpaqueSecondary, in: Circle())
    }
}
