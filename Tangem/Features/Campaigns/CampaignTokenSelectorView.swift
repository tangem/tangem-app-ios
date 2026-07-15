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
                    TokenSelectorEmptyContentView(message: Localization.expressTokenListEmptySearch)
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
            .background(Colors.Background.tertiary.ignoresSafeArea())
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
