//
//  OnboardingSeedPhraseImportView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SeedPhraseSuggestionsView: View {
    let suggestions: [String]
    let tappedSuggestion: (Int) -> Void

    @ViewBuilder
    private func bubble(with text: String, index: Int) -> some View {
        Button {
            tappedSuggestion(index)
        } label: {
            Text(text)
                .style(Fonts.Regular.footnote, color: Colors.Text.primary2)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Colors.Icon.primary1)
                .cornerRadiusContinuous(10)
        }
    }

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(0 ..< suggestions.count, id: \.self) { index in
                    bubble(with: suggestions[index], index: index)
                }
            }
        }
    }
}

struct OnboardingSeedPhraseImportView: View {
    @ObservedObject var viewModel: OnboardingSeedPhraseImportViewModel

    var body: some View {
        VStack(spacing: 0) {
            Text(Localization.onboardingSeedImportMessage)
                .style(Fonts.Regular.callout, color: Colors.Text.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
                .padding(.top, 26)

            SeedPhraseTextView(inputProcessor: viewModel.inputProcessor)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Colors.Field.primary)
                .cornerRadiusContinuous(14)
                .frame(maxHeight: 154)
                .padding(.top, 20)

            Text(viewModel.inputError ?? " ")
                .style(Fonts.Regular.footnote, color: Colors.Text.warning)
                .padding(.top, 8)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            SeedPhraseSuggestionsView(suggestions: viewModel.suggestions, tappedSuggestion: viewModel.tappedSuggestion(at:))

            MainButton(
                title: Localization.commonImport,
                icon: .leading(Assets.tangemIcon),
                style: .primary,
                isLoading: false,
                isDisabled: !viewModel.isSeedPhraseValid,
                action: viewModel.importSeedPhrase
            )
            .padding(.vertical, 16)
            .keyboardAdaptive()
        }
        .alert(item: $viewModel.errorAlert, content: { alertBinder in
            alertBinder.alert
        })
        .padding(.horizontal, 16)
    }
}

struct OnboardingSeedPhraseImportView_Previews: PreviewProvider {
    private static let viewModel = OnboardingSeedPhraseImportViewModel(
        inputProcessor: SeedPhraseInputProcessor(),
        outputHandler: { _ in }
    )

    static var previews: some View {
        OnboardingSeedPhraseImportView(viewModel: viewModel)
    }
}
