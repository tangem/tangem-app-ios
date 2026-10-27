//
//  OnboardingSeedPhraseUserValidationView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI

struct OnboardingSeedPhraseUserValidationView: View {
    @ObservedObject var viewModel: OnboardingSeedPhraseUserValidationViewModel

    @State private var containerSize: CGSize = .zero
    @State private var contentSize: CGSize = .zero

    @State private var isButtonPositionAnimationEnabled = false

    var body: some View {
        VStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Text(Localization.onboardingSeedUserValidationTitle)
                        .style(Fonts.Bold.title1, color: DesignSystem.Color.textPrimary)
                        .padding(.top, 40)

                    Text(Localization.onboardingSeedUserValidationMessage)
                        .style(Fonts.Regular.callout, color: DesignSystem.Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 14)
                        .padding(.horizontal, 32)

                    WordInputView(
                        wordNumber: 2,
                        hasError: viewModel.firstInputHasError,
                        text: $viewModel.firstInputText
                    )
                    .padding(.top, 38)

                    WordInputView(
                        wordNumber: 7,
                        hasError: viewModel.secondInputHasError,
                        text: $viewModel.secondInputText
                    )
                    .padding(.top, 20)

                    WordInputView(
                        wordNumber: 11,
                        hasError: viewModel.thirdInputHasError,
                        text: $viewModel.thirdInputText
                    )
                    .padding(.top, 20)

                    Color.clear
                        .frame(minHeight: max(20, containerSize.height - contentSize.height))
                }
                .readGeometry(\.size) { contentSize in
                    if self.contentSize == .zero {
                        self.contentSize = contentSize
                    }
                }
            }
            .readGeometry(\.size, inCoordinateSpace: .local) { containerSize in
                if self.containerSize != .zero, !isButtonPositionAnimationEnabled {
                    isButtonPositionAnimationEnabled = true
                }
                self.containerSize = containerSize
            }

            MainButton(
                title: viewModel.actionTitle,
                icon: viewModel.actionIcon,
                style: .primary,
                isLoading: false,
                isDisabled: !viewModel.isCreateWalletButtonEnabled,
                action: viewModel.createWallet
            )
            .padding(.bottom, 6)
        }
        .animation(isButtonPositionAnimationEnabled ? .easeOut(duration: 0.35) : nil, value: containerSize)
        .padding(.horizontal, 16)
    }
}

private struct WordInputView: View {
    let wordNumber: Int
    let hasError: Bool
    let text: Binding<String>

    @State private var isResponder: Bool? = nil

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Text("\(wordNumber).")
                .style(
                    Fonts.Regular.body,
                    color: hasError ? DesignSystem.Color.textAccentRed : DesignSystem.Color.textSecondary
                )
                .frame(width: 38, alignment: .leading)
                .padding(.leading, 16)
                .layoutPriority(1000.0)

            HStack(spacing: 0.0) {
                CustomTextField(
                    text: text,
                    isResponder: $isResponder,
                    actionButtonTapped: .constant(false),
                    clearsOnBeginEditing: false,
                    handleKeyboard: true,
                    keyboard: .asciiCapable,
                    clearButtonMode: .never,
                    textColor: UIColor(hasError ? DesignSystem.Color.textAccentRed : DesignSystem.Color.textPrimary),
                    font: UIFonts.Regular.body,
                    placeholder: "",
                    isEnabled: true
                )
                .setAutocapitalizationType(.none)
                .padding(.vertical, 12)

                if isResponder ?? false {
                    SwiftUI.Button(action: { text.wrappedValue = "" }) {
                        Assets.clear.image
                            .foregroundColor(DesignSystem.Color.iconSecondary)
                            .padding(.horizontal, 16)
                    }
                }
            }
            .screenCaptureProtection()
        }
        .frame(minHeight: 46)
        .background(DesignSystem.Color.bgTertiary)
        .cornerRadiusContinuous(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(hasError ? DesignSystem.Color.borderAccentRed : .clear, lineWidth: 1)
                .padding(.horizontal, 1) // offset the border to the inside, otherwise it cuts off
        )
        .simultaneousGesture(TapGesture().onEnded {
            isResponder = true
        })
    }
}

#Preview {
    OnboardingSeedPhraseUserValidationView(
        viewModel: OnboardingSeedPhraseUserValidationViewModel(
            mode: .card,
            validationInput: .init(
                secondWord: "tree",
                seventhWord: "lunar",
                eleventhWord: "banana",
                createWalletAction: {}
            )
        )
    )
}
