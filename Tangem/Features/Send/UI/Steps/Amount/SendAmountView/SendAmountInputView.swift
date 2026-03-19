//
//  SendAmountInputView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemAccessibilityIdentifiers
import enum TangemFoundation.FeedbackGenerator

struct SendAmountInputView<FocusField: Hashable>: View {
    @ObservedObject var field: AmountInputFieldModel
    let fiatIconURL: URL?
    @FocusState.Binding var focusedField: FocusField?
    let cryptoFocusValue: FocusField
    let fiatFocusValue: FocusField
    var accessibilityConfiguration: SendAmountInputAccessibilityConfiguration?
    var onWillToggle: (() -> Void)?

    var body: some View {
        VStack(alignment: .center, spacing: .zero) {
            textField
            bottomView
        }
        .animation(SendAmountInputConstants.animation, value: field.amountType)
    }
}

// MARK: - Private

private extension SendAmountInputView {
    var useFiatCalculation: Bool {
        field.amountType == .fiat
    }

    @ViewBuilder
    var textField: some View {
        switch field.amountType {
        case .crypto:
            makeTextField(viewModel: field.cryptoTextFieldViewModel, options: field.cryptoTextFieldOptions, focusValue: cryptoFocusValue)
                .transition(SendAmountInputConstants.textFieldTransition)
        case .fiat:
            makeTextField(viewModel: field.fiatTextFieldViewModel, options: field.fiatTextFieldOptions, focusValue: fiatFocusValue)
                .transition(SendAmountInputConstants.textFieldTransition)
        }
    }

    func makeTextField(
        viewModel: DecimalNumberTextFieldViewModel,
        options: SendDecimalNumberTextField.PrefixSuffixOptions?,
        focusValue: FocusField
    ) -> some View {
        SendDecimalNumberTextField(viewModel: viewModel)
            .optionalAccessibilityIdentifier(accessibilityConfiguration?.textFieldIdentifier)
            .optionalPrefixSuffixAccessibilityIdentifier(accessibilityConfiguration?.currencySymbolIdentifier)
            .prefixSuffixOptions(options)
            .alignment(.center)
            .minTextScale(SendAmountStep.Constants.amountMinTextScale)
            .appearance(.init(font: Fonts.Regular.largeTitle.weight(.semibold)))
            .focused($focusedField, equals: focusValue)
            .frame(height: 42)
    }

    @ViewBuilder
    var bottomView: some View {
        Group {
            if let bottomInfoText = field.bottomInfoText {
                switch bottomInfoText {
                case .info(let string):
                    Text(string)
                        .style(Fonts.Regular.subheadline, color: Colors.Text.attention)
                        .padding(.vertical, 8)
                case .error(let string):
                    Text(string)
                        .style(Fonts.Regular.subheadline, color: Colors.Text.warning)
                        .padding(.vertical, 8)
                        .optionalAccessibilityIdentifier(accessibilityConfiguration?.errorIdentifier)
                }
            } else if field.possibleToConvertToFiat {
                Button(action: {
                    if focusedField != nil {
                        onWillToggle?()
                    }

                    field.amountType = useFiatCalculation ? .crypto : .fiat
                    FeedbackGenerator.heavy()
                }) {
                    alternativeView
                }
                .optionalAccessibilityIdentifier(accessibilityConfiguration?.toggleButtonIdentifier)
            } else {
                Text(" ")
                    .style(Fonts.Regular.subheadline, color: Colors.Text.tertiary)
                    .padding(.vertical, 8)
            }
        }
        .multilineTextAlignment(.center)
        .lineLimit(2)
    }

    var alternativeView: some View {
        HStack(spacing: 8) {
            Assets.Glyphs.exchange.image
                .rotation3DEffect(.degrees(useFiatCalculation ? 180 : .zero), axis: (1, 0, 0))
                .animation(SendAmountInputConstants.animation, value: useFiatCalculation)
                .zIndex(1)

            HStack(spacing: 4) {
                Text(field.alternativeAmount)
                    .style(Fonts.Bold.subheadline, color: Colors.Text.secondary)
                    .lineLimit(1)
                    .optionalAccessibilityIdentifier(accessibilityConfiguration?.alternativeAmountIdentifier(useFiatCalculation))

                IconView(
                    url: useFiatCalculation ? field.cryptoIconURL : fiatIconURL,
                    size: CGSize(width: 14, height: 14)
                )
            }
            .id(useFiatCalculation)
            .animation(.none, value: field.alternativeAmount)
            .transition(SendAmountInputConstants.alternativeAmountTransition)
        }
        .animation(SendAmountInputConstants.animation, value: field.alternativeAmount)
        .padding(.all, 8)
    }
}

// MARK: - AccessibilityConfiguration

struct SendAmountInputAccessibilityConfiguration {
    let textFieldIdentifier: String?
    let currencySymbolIdentifier: String?
    let toggleButtonIdentifier: String?
    let errorIdentifier: String?
    let alternativeAmountIdentifier: (_ isFiat: Bool) -> String?

    static var source: SendAmountInputAccessibilityConfiguration {
        .init(
            textFieldIdentifier: SendAccessibilityIdentifiers.decimalNumberTextField,
            currencySymbolIdentifier: SendAccessibilityIdentifiers.currencySymbol,
            toggleButtonIdentifier: SendAccessibilityIdentifiers.currencyToggleButton,
            errorIdentifier: SendAccessibilityIdentifiers.totalExceedsBalanceBanner,
            alternativeAmountIdentifier: { isFiat in
                isFiat
                    ? SendAccessibilityIdentifiers.alternativeCryptoAmount
                    : SendAccessibilityIdentifiers.alternativeFiatAmount
            }
        )
    }
}

// MARK: - Constants

enum SendAmountInputConstants {
    static let duration: TimeInterval = 0.2
    static let animation: Animation = .easeOut(duration: duration)

    static let textFieldTransition: AnyTransition = .asymmetric(
        insertion: .offset(y: 30)
            .animation(SendAmountInputConstants.animation.delay(SendAmountInputConstants.duration)),
        removal: .offset(y: 30)
            .animation(SendAmountInputConstants.animation)
            .combined(with: .opacity)
            .animation(SendAmountInputConstants.animation.speed(2))
    )
    .combined(with: .scale(scale: 0.95, anchor: .bottom))
    .combined(with: .opacity)

    static let alternativeAmountTransition: AnyTransition = .asymmetric(
        insertion: .offset(x: 50).animation(SendAmountInputConstants.animation.delay(SendAmountInputConstants.duration)),
        removal: .offset(x: -50).animation(SendAmountInputConstants.animation)
    )
    .combined(with: .opacity)
}

// MARK: - Helpers

private extension SendDecimalNumberTextField {
    func optionalAccessibilityIdentifier(_ identifier: String?) -> SendDecimalNumberTextField {
        if let identifier {
            return accessibilityIdentifier(identifier)
        }
        return self
    }

    func optionalPrefixSuffixAccessibilityIdentifier(_ identifier: String?) -> SendDecimalNumberTextField {
        if let identifier {
            return prefixSuffixAccessibilityIdentifier(identifier)
        }
        return self
    }
}

private extension View {
    @ViewBuilder
    func optionalAccessibilityIdentifier(_ identifier: String?) -> some View {
        if let identifier {
            accessibilityIdentifier(identifier)
        } else {
            self
        }
    }
}
