//
//  PolymarketSearchBlockView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct PolymarketSearchBlockView: View {
    @ObservedObject var viewModel: PolymarketSearchBlockViewModel

    var body: some View {
        ZStack {
            if viewModel.isSearching {
                ZStack {
                    DesignSystem.Color.bgPrimary
                        .ignoresSafeArea()

                    PolymarketSearchResultsView(viewModel: viewModel)
                }
                .transition(.opacity)
            }
        }
        .animation(.default, value: viewModel.isSearching)
    }
}
