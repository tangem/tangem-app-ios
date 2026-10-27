//
//  SwapSummaryFeeSectionView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils
import TangemAssets
import TangemAccessibilityIdentifiers

struct SwapSummaryFeeSectionView: View {
    @ObservedObject var slippageViewModel: SwapSummarySlippageViewModel
    @ObservedObject var feeViewModel: SendFeeCompactViewModel
    let showsSlippage: Bool
    let slippageTapAction: () -> Void
    let feeTapAction: () -> Void

    private var isSlippageVisible: Bool {
        showsSlippage && slippageViewModel.isVisible
    }

    var body: some View {
        if isSlippageVisible || feeViewModel.feeCompactViewIsVisible {
            VStack(spacing: .zero) {
                if isSlippageVisible {
                    SwapSummarySlippageView(viewModel: slippageViewModel, tapAction: slippageTapAction)

                    if feeViewModel.feeCompactViewIsVisible {
                        Separator(color: DesignSystem.Color.borderSecondary)
                            .padding(.horizontal, 14)
                    }
                }

                if feeViewModel.feeCompactViewIsVisible {
                    FeeCompactView(viewModel: feeViewModel.feeCompactViewModel, tapAction: feeTapAction)
                        .embedded(true)
                        .accessibilityElement(children: .combine)
                        .accessibilityIdentifier(SwapAccessibilityIdentifiers.feeBlock)
                }
            }
            .defaultRoundedBackground(with: DesignSystem.Color.bgSecondary, verticalPadding: .zero, horizontalPadding: .zero)
        }
    }
}
