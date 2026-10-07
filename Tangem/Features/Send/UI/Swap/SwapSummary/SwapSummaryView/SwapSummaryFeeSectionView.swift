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
    let feeTapAction: () -> Void

    private var isSlippageVisible: Bool {
        showsSlippage && slippageViewModel.isVisible
    }

    var body: some View {
        if slippageViewModel.isCustomSlippageAvailable {
            groupedSection
        } else {
            SendFeeCompactView(viewModel: feeViewModel, tapAction: feeTapAction)
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier(SwapAccessibilityIdentifiers.feeBlock)
        }
    }

    @ViewBuilder
    private var groupedSection: some View {
        if isSlippageVisible || feeViewModel.feeCompactViewIsVisible {
            VStack(spacing: .zero) {
                if isSlippageVisible {
                    SwapSummarySlippageView()

                    if feeViewModel.feeCompactViewIsVisible {
                        Separator(color: Colors.Stroke.primary)
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
            .defaultRoundedBackground(with: Colors.Background.action, verticalPadding: .zero, horizontalPadding: .zero)
        }
    }
}
