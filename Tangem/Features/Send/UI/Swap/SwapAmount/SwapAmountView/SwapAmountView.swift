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
    @State private var isShaking: Bool = false

    var body: some View {
        VStack(spacing: 14) {
            sourceView

            receiveView
        }
        .overlay(alignment: .center) { swappingButton }
    }

    private var sourceView: some View {
        ExpressCurrencyView(viewModel: viewModel.sourceExpressCurrencyViewModel) {
            SendDecimalNumberTextField(viewModel: viewModel.sourceDecimalNumberTextFieldViewModel)
                .minTextScale(SendAmountStep.Constants.amountMinTextScale)
                .alignment(.leading)
                .offset(x: isShaking ? 10 : 0)
                .simultaneousGesture(TapGesture().onEnded {
                    viewModel.textFieldDidTapped()
                })
                .onChange(of: viewModel.sourceExpressCurrencyViewModel.errorState) { errorState in
                    guard case .insufficientFunds = errorState else {
                        return
                    }

                    isShaking = true
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.2, blendDuration: 0.2)) {
                        isShaking = false
                    }
                }
        }
        .didTapChangeCurrency(viewModel.userDidTapChangeSourceTokenButton)
        .defaultRoundedBackground(with: Colors.Background.action)
        .accessibilityIdentifier(SwapAccessibilityIdentifiers.fromAmountTextField)
    }

    private var receiveView: some View {
        ExpressCurrencyView(viewModel: viewModel.receiveExpressCurrencyViewModel) {
            LoadableTextView(
                state: viewModel.receiveCryptoAmountState,
                font: Fonts.Regular.title1,
                textColor: Colors.Text.primary1,
                loaderSize: CGSize(width: 102, height: 24),
                prefix: "~"
            )
        }
        .didTapChangeCurrency(viewModel.userDidTapChangeReceiveTokenButton)
        .didTapNetworkFeeInfoButton { type in
            viewModel.userDidTapNetworkFeeInfoButton(type.message)
        }
        .defaultRoundedBackground(with: Colors.Background.action)
        .accessibilityIdentifier(SwapAccessibilityIdentifiers.fromAmountTextField)
    }

    private var swappingButton: some View {
        Button(action: viewModel.userDidTapSwapSourceAndReceiveTokensButton) {
            Assets.swappingIcon.image
                .renderingMode(.template)
                .resizable()
                .frame(width: 20, height: 20)
                .foregroundColor(viewModel.isSwapButtonDisabled ? Colors.Icon.inactive : Colors.Icon.primary1)
        }
        .disabled(viewModel.isSwapButtonDisabled)
        .frame(width: 44, height: 44)
        .background(Colors.Background.primary)
        .cornerRadius(22)
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Colors.Stroke.primary, lineWidth: 1)
        )
    }
}
