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
    @State private var isCompactContentVisible: Bool = true

    var body: some View {
        VStack(spacing: 14) {
            sourceView

            receiveView
        }
        .overlay(alignment: .center) { swappingButton }
        .animation(.easeInOut(duration: 0.45), value: viewModel.activeField)
        .onChange(of: viewModel.activeField) { _ in
            isCompactContentVisible = false
            withAnimation(.easeInOut(duration: 0.25).delay(0.2)) {
                isCompactContentVisible = true
            }
        }
    }

    @ViewBuilder
    private var sourceView: some View {
        if viewModel.isFixedRateMode, viewModel.activeField != .source {
            // Compact source view — tappable to expand
            ExpressCurrencyView(viewModel: viewModel.sourceExpressCurrencyViewModel) {
                LoadableTextView(
                    state: sourceCompactAmountState,
                    font: Fonts.Regular.title1,
                    textColor: Colors.Text.primary1,
                    loaderSize: CGSize(width: 102, height: 24),
                    prefix: ""
                )
            }
            .didTapChangeCurrency(viewModel.userDidTapChangeSourceTokenButton)
            .defaultRoundedBackground(with: Colors.Background.action)
            .accessibilityIdentifier(SwapAccessibilityIdentifiers.fromAmountTextField)
            .opacity(isCompactContentVisible ? 1 : 0)
            .contentShape(Rectangle())
            .onTapGesture {
                viewModel.userDidTapSourceField()
            }
        } else {
            // Expanded source view with text field
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
    }

    @ViewBuilder
    private var receiveView: some View {
        if viewModel.isFixedRateMode, viewModel.activeField == .receive {
            // Expanded receive view with editable text field
            ExpressCurrencyView(viewModel: viewModel.receiveExpressCurrencyViewModel) {
                SendDecimalNumberTextField(viewModel: viewModel.receiveDecimalNumberTextFieldViewModel)
                    .minTextScale(SendAmountStep.Constants.amountMinTextScale)
                    .alignment(.leading)
            }
            .didTapChangeCurrency(viewModel.userDidTapChangeReceiveTokenButton)
            .didTapNetworkFeeInfoButton { type in
                viewModel.userDidTapNetworkFeeInfoButton(type.message)
            }
            .defaultRoundedBackground(with: Colors.Background.action)
            .accessibilityIdentifier(SwapAccessibilityIdentifiers.fromAmountTextField)
        } else if viewModel.isFixedRateMode, viewModel.activeField != .receive {
            // Compact receive view — tappable to expand
            ExpressCurrencyView(viewModel: viewModel.receiveExpressCurrencyViewModel) {
                LoadableTextView(
                    state: viewModel.receiveCryptoAmountState,
                    font: Fonts.Regular.title1,
                    textColor: Colors.Text.primary1,
                    loaderSize: CGSize(width: 102, height: 24),
                    prefix: ""
                )
            }
            .didTapChangeCurrency(viewModel.userDidTapChangeReceiveTokenButton)
            .didTapNetworkFeeInfoButton { type in
                viewModel.userDidTapNetworkFeeInfoButton(type.message)
            }
            .defaultRoundedBackground(with: Colors.Background.action)
            .accessibilityIdentifier(SwapAccessibilityIdentifiers.fromAmountTextField)
            .opacity(isCompactContentVisible ? 1 : 0)
            .contentShape(Rectangle())
            .onTapGesture {
                viewModel.userDidTapReceiveField()
            }
        } else {
            // Non-fixed-rate mode: read-only receive view (original behavior)
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
    }

    private var sourceCompactAmountState: LoadableTextView.State {
        let text = viewModel.sourceDecimalNumberTextFieldViewModel.textFieldTextBinding.value
        if text.isEmpty {
            return .loaded(text: "0")
        }
        return .loaded(text: text)
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
