//
//  SwapSummaryProviderCompactView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct SwapSummaryProviderCompactView: View {
    @ObservedObject var viewModel: SwapSummaryProviderViewModel
    @Binding var shouldAnimateBestRateBadge: Bool

    var body: some View {
        if viewModel.providerState != nil {
            Button(action: viewModel.userDidTap) {
                SendSwapProviderCompactView(
                    data: viewModel.compactData,
                    shouldAnimateBestRateBadge: $shouldAnimateBestRateBadge
                )
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.compactData.isTappable)
            .background(Colors.Background.action)
            .cornerRadiusContinuous(14)
            .contentShape(.rect)
            .transition(.opacity.animation(.easeInOut))
        }
    }
}
