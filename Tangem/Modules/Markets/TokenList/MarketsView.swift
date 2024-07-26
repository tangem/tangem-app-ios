//
//  MarketsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import BlockchainSdk

struct MarketsView: View {
    @ObservedObject var viewModel: MarketsViewModel

    var body: some View {
        ZStack(alignment: .topLeading) {
            if viewModel.isSearching {
                searchResultView
            } else {
                defaultMarketsView
            }
        }
        .scrollDismissesKeyboardCompat(.immediately)
        .background(Colors.Background.primary)
        .alert(item: $viewModel.alert, content: { $0.alert })
        .background(Colors.Background.primary)
    }

    @ViewBuilder
    private var defaultMarketsView: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 12) {
                Text(Localization.marketsCommonTitle)
                    .style(Fonts.Bold.title3, color: Colors.Text.primary1)

                MarketsRatingHeaderView(viewModel: viewModel.marketsRatingHeaderViewModel)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)

            list
        }

        if case .error = viewModel.tokenListLoadingState {
            errorStateView
        }
    }

    @ViewBuilder
    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.tokenViewModels) {
                    MarketsItemView(viewModel: $0)
                }

                if viewModel.isShowUnderCapButton {
                    showTokensUnderCapView
                }

                // Need for display list skeleton view
                if case .loading = viewModel.tokenListLoadingState {
                    loadingSkeletons
                }
            }
        }
    }

    private var loadingSkeletons: some View {
        ForEach(0 ..< 20) { _ in
            MarketsSkeletonItemView()
        }
    }

    @ViewBuilder
    private var searchResultView: some View {
        switch viewModel.tokenListLoadingState {
        case .noResults:
            noResultsStateView
        case .error:
            errorStateView
        case .loading, .allDataLoaded, .idle:
            VStack(spacing: 12) {
                Text(Localization.marketsSearchResultTitle)
                    .style(Fonts.Bold.body, color: Colors.Text.primary1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)

                list
            }
        }
    }

    private var showTokensUnderCapView: some View {
        VStack(alignment: .center, spacing: 8) {
            HStack(spacing: .zero) {
                Text(Localization.marketsSearchSeeTokensUnder100k)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
            }

            HStack(spacing: .zero) {
                Button(action: {
                    viewModel.onShowUnderCapAction()
                }, label: {
                    HStack(spacing: .zero) {
                        Text(Localization.marketsSearchShowTokens)
                            .style(Fonts.Bold.footnote, color: Colors.Text.primary1)
                    }
                })
                .roundedBackground(with: Colors.Button.secondary, verticalPadding: 8, horizontalPadding: 14, radius: 10)
            }
        }
        .padding(.vertical, 12)
    }

    private var noResultsStateView: some View {
        Text(Localization.marketsSearchTokenNoResultTitle)
            .style(Fonts.Bold.caption1, color: Colors.Text.tertiary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 16)
    }

    private var errorStateView: some View {
        VStack(spacing: 12) {
            Text(Localization.marketsLoadingErrorTitle)
                .style(Fonts.Bold.caption1, color: Colors.Text.tertiary)

            Button(action: {
                viewModel.onTryLoadList()
            }, label: {
                HStack(spacing: .zero) {
                    Text(Localization.tryToLoadDataAgainButtonTitle)
                        .style(Fonts.Regular.footnote.bold(), color: Colors.Text.primary1)
                }
            })
            .roundedBackground(with: Colors.Button.secondary, verticalPadding: 6, horizontalPadding: 12, radius: 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 16)
    }
}

extension MarketsView {
    enum ListLoadingState: Int, Identifiable, Hashable {
        var id: Int { rawValue }

        case noResults
        case error
        case loading
        case allDataLoaded
        case idle
    }
}
