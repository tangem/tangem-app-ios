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
            NewTokenSelectorView(viewModel: viewModel.tokenSelectorViewModel) {
                NewTokenSelectorEmptyContentView(message: Localization.expressTokenListEmptySearch)
            }
            .searchType(.native)
            .background(Colors.Background.tertiary.ignoresSafeArea())
            .navigationTitle(Localization.swappingTokenListTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    CircleButton.close(action: viewModel.close)
                }
            }
        }
        .onDisappear(perform: viewModel.onDisappear)
    }
}
