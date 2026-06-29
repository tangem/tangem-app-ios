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
    @FocusState private var focusedSourceField: SourceField?

    var body: some View {
        VStack(spacing: 14) {
            sourceView

            receiveView
        }
        .overlay(alignment: .center) { swappingButton }
    }

    private var sourceView: some View {
        ExpressCurrencyView(viewModel: viewModel.sourceExpressCurrencyViewModel) {
            sourceTextField
        }
        .didTapChangeCurrency(viewModel.userDidTapChangeSourceTokenButton)
        .didTapSwitchCurrency(isSwitched: viewModel.sourceCalculationType == .fiat) {
            if focusedSourceField != nil {
                focusedSourceField = viewModel.sourceCalculationType == .fiat ? .crypto : .fiat
            }

            viewModel.userDidTapSwitchCurrencyButton()
        }
        .animation(SendAmountInputConstants.animation, value: viewModel.sourceCalculationType)
        .defaultRoundedBackground(with: Colors.Background.action)
        .accessibilityIdentifier(SwapAccessibilityIdentifiers.fromAmountTextField)
    }

    @ViewBuilder
    private var sourceTextField: some View {
        switch viewModel.sourceCalculationType {
        case .crypto:
            makeSourceTextField(
                textFieldViewModel: viewModel.sourceCryptoDecimalNumberTextFieldViewModel,
                options: .none,
                focusValue: .crypto
            )
            .transition(SendAmountInputConstants.textFieldTransition)

        case .fiat:
            makeSourceTextField(
                textFieldViewModel: viewModel.sourceFiatDecimalNumberTextFieldViewModel,
                options: viewModel.sourceFiatFieldOptions,
                focusValue: .fiat
            )
            .transition(SendAmountInputConstants.textFieldTransition)
        }
    }

    private func makeSourceTextField(
        textFieldViewModel: DecimalNumberTextFieldViewModel,
        options: SendDecimalNumberTextField.PrefixSuffixOptions?,
        focusValue: SourceField
    ) -> some View {
        SendDecimalNumberTextField(viewModel: textFieldViewModel)
            .prefixSuffixOptions(options)
            .minTextScale(SendAmountStep.Constants.amountMinTextScale)
            .alignment(.leading)
            .focused($focusedSourceField, equals: focusValue)
            .disabled(viewModel.isInputDisabled)
            .offset(x: isShaking ? 10 : 0)
            .simultaneousGesture(TapGesture().onEnded {
                viewModel.textFieldDidTap()
            })
            .onChange(of: viewModel.sourceExpressCurrencyViewModel.state.errorState) { errorState in
                guard case .insufficientFunds = errorState else {
                    return
                }

                isShaking = true
                withAnimation(.spring(response: 0.2, dampingFraction: 0.2, blendDuration: 0.2)) {
                    isShaking = false
                }
            }
    }

    private var receiveView: some View {
        ExpressCurrencyView(viewModel: viewModel.receiveExpressCurrencyViewModel) {
            LoadableTextView(
                state: viewModel.receiveCryptoAmountState,
                font: Fonts.Regular.title1,
                textColor: Colors.Text.primary1,
                loaderSize: CGSize(width: 102, height: 24)
            )
        }
        .didTapChangeCurrency(viewModel.userDidTapChangeReceiveTokenButton)
        .didTapNetworkFeeInfoButton { type in
            viewModel.userDidTapNetworkFeeInfoButton(type.message)
        }
        .defaultRoundedBackground(with: Colors.Background.action)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(SwapAccessibilityIdentifiers.toAmountTextField)
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
        .accessibilityIdentifier(SwapAccessibilityIdentifiers.swapTokensButton)
    }
}

// MARK: - SourceField

private extension SwapAmountView {
    enum SourceField: Hashable {
        case crypto
        case fiat
    }
}
