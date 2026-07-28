//
//  CampaignTokenSelectorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct CampaignTokenSelectorView: View {
    @ObservedObject var viewModel: CampaignTokenSelectorViewModel

    var body: some View {
        NavigationStack {
            TokenSelectorView(
                viewModel: viewModel.tokenSelectorViewModel,
                emptyContentView: {
                    SearchOnlyEmptyContentView(tokenSelectorViewModel: viewModel.tokenSelectorViewModel)
                },
                headerContent: {
                    Text(Localization.marketsSearchPortfolioHeader)
                        .style(Fonts.Bold.title3, color: Colors.Text.primary1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 8)
                },
                additionalContent: {
                    CampaignEligibleTokensView(
                        rows: viewModel.eligibleTokenRows,
                        onAdd: viewModel.addToken
                    )
                }
            )
            .searchType(.native)
            .showsSeparators(false)
            .background(Color.Tangem.Surface.level2.ignoresSafeArea())
            .navigationTitle(Localization.swappingTokenListTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                NavigationToolbarButton.close(placement: .topBarTrailing, action: viewModel.dismiss)
            }
        }
        .overlay {
            FloatingSheetView(
                viewModel: viewModel.addTokenFlowViewModel,
                dismissSheetAction: viewModel.dismissAddToken
            )
            .allowsHitTesting(viewModel.addTokenFlowViewModel != nil)
        }
    }
}

// MARK: - SearchOnlyEmptyContentView

private struct SearchOnlyEmptyContentView: View {
    @ObservedObject var tokenSelectorViewModel: TokenSelectorViewModel

    var body: some View {
        if !tokenSelectorViewModel.searchText.isEmpty {
            TokenSelectorEmptyContentView(message: Localization.expressTokenListEmptySearch)
        }
    }
}
