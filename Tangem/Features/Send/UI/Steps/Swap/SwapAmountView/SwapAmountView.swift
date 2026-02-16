//
//  SwapAmountView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUIUtils
import TangemUI
import TangemAccessibilityIdentifiers

struct SwapAmountView: View {
    @ObservedObject var viewModel: SwapAmountViewModel

    var body: some View {
        VStack(spacing: 14) {
            GroupedSection(viewModel.swapSourceTokenViewModel) {
                SwapSourceTokenView(viewModel: $0)
                    .didTapChangeCurrency(viewModel.userDidTapChangeSourceTokenButton)
                    .accessibilityIdentifier(SwapAccessibilityIdentifiers.fromAmountTextField)
            }
            .innerContentPadding(12)
            .backgroundColor(Colors.Background.action)

            GroupedSection(viewModel.swapReceiveTokenViewModel) {
                SwapReceiveTokenView(viewModel: $0)
                    .didTapChangeCurrency(viewModel.userDidTapChangeReceiveTokenButton)
                    .accessibilityIdentifier(SwapAccessibilityIdentifiers.fromAmountTextField)
            }
            .innerContentPadding(12)
            .backgroundColor(Colors.Background.action)
        }
        .overlay(alignment: .center) { swappingButton }
        .padding(.top, 10) // Check it
    }

    private var swappingButton: some View {
        Button(action: viewModel.userDidTapSwapSourceAndReceiveTokensButton) {
            if viewModel.isSwapButtonLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Colors.Icon.informative))
            } else {
                Assets.swappingIcon.image
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundColor(viewModel.isSwapButtonDisabled ? Colors.Icon.inactive : Colors.Icon.primary1)
            }
        }
        .disabled(viewModel.isSwapButtonLoading || viewModel.isSwapButtonDisabled)
        .frame(width: 44, height: 44)
        .background(Colors.Background.primary)
        .cornerRadius(22)
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Colors.Stroke.primary, lineWidth: 1)
        )
    }
}
