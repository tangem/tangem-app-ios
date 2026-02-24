//
//  SwapSummaryProviderView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct SwapSummaryProviderView: View {
    @ObservedObject var viewModel: SwapSummaryProviderViewModel

    var body: some View {
        GroupedSection(viewModel.providerState) { state in
            switch state {
            case .loading:
                LoadingProvidersRow()
            case .loaded(let data):
                ProviderRowView(viewModel: data)
            }
        }
        .innerContentPadding(12)
        .backgroundColor(Colors.Background.action)
        .transition(.opacity.animation(.easeInOut))
        .animation(.easeInOut, value: viewModel.providerState?.id)
    }
}
