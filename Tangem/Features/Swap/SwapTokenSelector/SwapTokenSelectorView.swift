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
            AccountsAwareTokenSelectorView(
                viewModel: viewModel.tokenSelectorViewModel,
                emptyContentView: {
                    AccountsAwareTokenSelectorEmptyContentView(message: Localization.expressTokenListEmptySearch)
                },
                additionalContent: {
                    if let viewModel = viewModel.marketsTokensViewModel {
                        SwapMarketsTokensView(
                            viewModel: viewModel
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
        .onDisappear(perform: viewModel.onDisappear)
    }
}
