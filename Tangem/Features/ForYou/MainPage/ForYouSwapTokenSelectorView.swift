//
//  ForYouSwapTokenSelectorView.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils
import TangemLocalization

struct ForYouSwapTokenSelectorView: View {
    @ObservedObject var viewModel: ForYouSwapTokenSelectorViewModel

    var body: some View {
        NavigationStack {
            TokenSelectorView(
                viewModel: viewModel.tokenSelectorViewModel,
                emptyContentView: { EmptyView() },
                headerContent: { EmptyView() },
                additionalContent: { EmptyView() }
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
    }
}
