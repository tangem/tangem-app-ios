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
            let content = SendSwapProviderCompactView(
                data: viewModel.compactData,
                shouldAnimateBestRateBadge: $shouldAnimateBestRateBadge
            )

            Group {
                if viewModel.compactData.isTappable {
                    Button(action: viewModel.userDidTap) { content }
                        .buttonStyle(.plain)
                } else {
                    content
                }
            }
            .background(Colors.Background.action)
            .cornerRadiusContinuous(14)
            .contentShape(.rect)
            .transition(.opacity.animation(.easeInOut))
        }
    }
}
