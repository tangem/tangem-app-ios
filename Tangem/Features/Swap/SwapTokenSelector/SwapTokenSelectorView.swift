//
//  SwapTokenSelectorView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct SwapTokenSelectorView: View {
    @ObservedObject var viewModel: SwapTokenSelectorViewModel

    var body: some View {
        NavigationStack {
            TokenSelectorView(
                viewModel: viewModel.tokenSelectorViewModel,
                emptyContentView: {
                    SwapTokenSelectorEmptyContentView(
                        tokenSelectorViewModel: viewModel.tokenSelectorViewModel,
                        marketsTokensViewModel: viewModel.marketsTokensViewModel,
                        message: Localization.expressTokenListEmptySearch
                    )
                },
                additionalContent: {
                    if let marketsTokensViewModel = viewModel.marketsTokensViewModel {
                        SwapMarketsTokensView(
                            viewModel: marketsTokensViewModel
                        )
                    } else if let offeredTokensViewModel = viewModel.offeredTokensViewModel {
                        SwapOfferedTokensSection(
                            viewModel: offeredTokensViewModel,
                            tokenSelectorViewModel: viewModel.tokenSelectorViewModel
                        )
                    }
                }
            )
            .sectionHeader(.init(title: Localization.swapYourAssetsTitle, showsItemsCount: true))
            .searchType(.native)
            .background(Colors.Background.tertiary.ignoresSafeArea())
            .navigationTitle(Localization.swappingTokenListTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                NavigationToolbarButton.close(placement: .topBarTrailing, action: viewModel.close)
            }
        }
        .onAppear(perform: viewModel.onAppear)
        .onDisappear(perform: viewModel.onDisappear)
    }
}

// MARK: - Offered tokens

private struct SwapOfferedTokensSection: View {
    @ObservedObject var viewModel: SwapOfferedTokensViewModel
    @ObservedObject var tokenSelectorViewModel: TokenSelectorViewModel

    var body: some View {
        SwapOfferedTokensView(
            rows: viewModel.rows,
            showsEmptyMessage: !tokenSelectorViewModel.contentVisibility.isEmpty,
            onAdd: viewModel.addToken
        )
    }
}
