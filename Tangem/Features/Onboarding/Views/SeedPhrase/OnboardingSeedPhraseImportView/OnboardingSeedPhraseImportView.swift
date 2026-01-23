//
//  OnboardingSeedPhraseImportView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI
import TangemUIUtils

struct OnboardingSeedPhraseImportView: View {
    @ObservedObject var viewModel: OnboardingSeedPhraseImportViewModel

    @State private var isResponder: Bool = false

    var body: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    VStack(spacing: 0) {
                        Text(Localization.onboardingSeedImportMessage)
                            .style(Fonts.Regular.callout, color: Colors.Text.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                            .padding(.top, 26)

                        SeedPhraseTextView(
                            inputProcessor: viewModel.inputProcessor,
                            handleKeyboard: false,
                            isResponder: isResponder
                        )
                        .screenCaptureProtection()
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Colors.Field.primary)
                        .cornerRadiusContinuous(14)
                        .frame(minHeight: 114, maxHeight: 154)
                        .padding(.top, 20)
                        .onDidAppear {
                            isResponder = true
                        }
                        .onWillDisappear {
                            isResponder = false
                        }

                        if let inputError = viewModel.inputError {
                            Text(inputError)
                                .style(Fonts.Regular.footnote, color: Colors.Text.warning)
                                .padding(.top, 8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .transition(.opacity)
                        }

                        passphraseView
                            .padding(.top, 14)
                    }
                    .padding(.horizontal, 16)

                    MainButton(
                        title: Localization.commonImport,
                        icon: viewModel.mainButtonIcon,
                        style: .primary,
                        isLoading: false,
                        isDisabled: !viewModel.isSeedPhraseValid,
                        action: viewModel.importSeedPhrase
                    )
                    .padding(.top, 14)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 6)
                }
            }

            VStack {
                Spacer()

                SeedPhraseSuggestionsView(suggestions: viewModel.suggestions, suggestionTapped: viewModel.suggestionTapped(at:))
                    .padding(.top, 22)
                    .padding(.bottom, 16)
                    .background(
                        ListFooterOverlayShadowView()
                            .padding(.top, -75)
                    )
                    .hidden(viewModel.suggestions.isEmpty)
                    .animation(nil, value: viewModel.suggestions)
            }
        }
        .screenCaptureProtection()
        .animation(.default, value: viewModel.inputError)
        .onAppear(perform: viewModel.onAppear)
        .onDisappear(perform: viewModel.onDisappear)
        .alert(item: $viewModel.errorAlert, content: { alertBinder in
            alertBinder.alert
        })
        .bottomSheet(
            item: $viewModel.passphraseBottomSheetModel,
            backgroundColor: Colors.Background.primary
        ) { model in
            OnboardingSeedPassphraseInfoBottomSheetView(model: model)
        }
    }

    private var passphraseView: some View {
        VStack(spacing: 2) {
            HStack(alignment: .center, spacing: 0) {
                Text(Localization.commonPassphrase)
                    .style(Fonts.Regular.footnote, color: Colors.Text.secondary)

                Button(action: viewModel.openPassphraseInfo, label: {
                    Assets.infoCircle20.image
                        .foregroundStyle(Colors.Icon.informative)
                        .padding(.horizontal, 4)
                })
                Spacer()
            }

            CustomTextField(
                text: $viewModel.passphrase,
                isResponder: $viewModel.isPassphraseInputResponder,
                actionButtonTapped: .constant(true),
                handleKeyboard: false,
                keyboard: .asciiCapable,
                clearButtonMode: .whileEditing,
                placeholder: Localization.sendOptionalField
            )
            .setAutocapitalizationType(.none)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Colors.Field.primary)
        .cornerRadiusContinuous(14)
    }
}

struct OnboardingSeedPhraseImportView_Previews: PreviewProvider {
    private static let viewModel = OnboardingSeedPhraseImportViewModel(
        inputProcessor: SeedPhraseInputProcessor(),
        shouldShowTangemIcon: true,
        delegate: nil
    )

    static var previews: some View {
        OnboardingSeedPhraseImportView(viewModel: viewModel)
    }
}
