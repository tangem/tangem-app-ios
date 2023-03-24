//
//  OnboardingSeedPhraseUserValidationView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct OnboardingSeedPhraseUserValidationView: View {
    @ObservedObject var viewModel: OnboardingSeedPhraseUserValidationViewModel

    @State private var containerSize: CGSize = .zero
    @State private var contentSize: CGSize = .zero

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                Text(Localization.onboardingSeedUserValidationTitle)
                    .style(Fonts.Bold.title1, color: Colors.Text.primary1)
                    .padding(.top, 40)

                Text(Localization.onboardingSeedUserValidationMessage)
                    .style(Fonts.Regular.callout, color: Colors.Text.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 14)

                WordInputView(
                    wordNumber: 2,
                    isWithError: viewModel.isFirstInputWithError,
                    textBinding: $viewModel.firstInputText
                )
                .padding(.top, 38)

                WordInputView(
                    wordNumber: 7,
                    isWithError: viewModel.isSecondInputWithError,
                    textBinding: $viewModel.secondInputText
                )
                .padding(.top, 20)

                WordInputView(
                    wordNumber: 11,
                    isWithError: viewModel.isThirdInputWithError,
                    textBinding: $viewModel.thirdInputText
                )
                .padding(.top, 20)

                Color.clear
                    .frame(minHeight: containerSize.height - contentSize.height)

                MainButton(
                    title: Localization.walletButtonCreateWallet,
                    icon: .leading(Assets.tangemIcon),
                    style: .primary,
                    isLoading: false,
                    isDisabled: !viewModel.isCreateWalletButtonEnabled,
                    action: viewModel.createWallet
                )
                .padding(.bottom, 10)
            }
            .readSize(onChange: { contentSize in
                if self.contentSize == .zero {
                    self.contentSize = contentSize
                }
            })
        }
        .readSize(onChange: { containerSize in
            if self.containerSize == .zero {
                self.containerSize = containerSize
            }
        })
        .padding(.horizontal, 16)
    }
}

fileprivate struct WordInputView: View {
    let wordNumber: Int
    let isWithError: Bool
    let textBinding: Binding<String>

    @State private var isResponder: Bool? = nil

    var body: some View {
        ZStack(alignment: .leading) {
            Text("\(wordNumber).")
                .style(
                    Fonts.Regular.body,
                    color: isWithError ? Colors.Text.warning : Colors.Text.tertiary
                )
                .padding(.leading, 16)
            CustomTextField(
                text: textBinding,
                isResponder: $isResponder,
                actionButtonTapped: .constant(false),
                clearsOnBeginEditing: false,
                handleKeyboard: true,
                clearButtonMode: .whileEditing,
                textColor: isWithError ? Colors.Text.warning.uiColorFromRGB() : Colors.Text.primary1.uiColorFromRGB(),
                font: UIFonts.Regular.body,
                placeholder: "",
                isEnabled: true
            )
            .padding(.vertical, 11)
            .padding(.leading, 54)
            .padding(.trailing, 10)
        }
        .frame(minHeight: 46)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isWithError ? Colors.Icon.warning : .clear, lineWidth: 1)
                .onTapGesture {
                    isResponder = true
                }
        )
        .background(Colors.Field.focused)
        .cornerRadius(14)
    }
}

struct OnboardingSeedPhraseUserValidationView_Previews: PreviewProvider {
    private static let viewModel = OnboardingSeedPhraseUserValidationViewModel(
        validationInput: .init(
            secondWord: "tree",
            seventhWord: "lunar",
            eleventhWord: "banana",
            createWalletAction: {}
        )
    )

    static var previews: some View {
        OnboardingSeedPhraseUserValidationView(viewModel: viewModel)
    }
}
