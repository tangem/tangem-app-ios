//
//  MarketsItemView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct MarketsItemView: View {
    @ObservedObject var viewModel: MarketsItemViewModel

    let cellWidth: CGFloat

    var body: some View {
        tokenItemView
            .onAppear {
                viewModel.onAppear()
            }
            .onDisappear {
                viewModel.onDisappear()
            }
    }

    private var tokenItemView: some View {
        MarketTokenItemView(viewModel: viewModel.tokenItemViewModel, cellWidth: cellWidth)
    }
}
