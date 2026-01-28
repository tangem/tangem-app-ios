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
    @ObservedObject private var tokenSelectorViewModel: AccountsAwareTokenSelectorViewModel

    @Environment(\.mainWindowSize) private var mainWindowSize

    init(viewModel: SwapTokenSelectorViewModel) {
        self.viewModel = viewModel
        tokenSelectorViewModel = viewModel.tokenSelectorViewModel
    }

    var body: some View {
        NavigationStack {
            AccountsAwareTokenSelectorView(
                viewModel: tokenSelectorViewModel,
                emptyContentView: {
                    AccountsAwareTokenSelectorEmptyContentView(message: Localization.expressTokenListEmptySearch)
                },
                additionalContent: {
                    ExpressExternalTokensSection(
                        viewModel: tokenSelectorViewModel,
                        cellWidth: mainWindowSize.width
                    )
                }
            )
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
