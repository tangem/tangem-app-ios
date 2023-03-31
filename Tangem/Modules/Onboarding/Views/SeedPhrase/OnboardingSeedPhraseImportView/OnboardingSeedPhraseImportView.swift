//
//  OnboardingSeedPhraseImportView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct OnboardingSeedPhraseImportView: View {
    @ObservedObject var viewModel: OnboardingSeedPhraseImportViewModel

    @State private var containerSize: CGSize = .zero
    @State private var contentSize: CGSize = .zero

    var body: some View {
        ScrollView(showsIndicators: false) {
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
                    .frame(minHeight: 114, maxHeight: 154)
                    .padding(.top, 20)

                Text(viewModel.inputError ?? " ")
                    .style(Fonts.Regular.footnote, color: Colors.Text.warning)
                    .padding(.top, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)

                SeedPhraseSuggestionsView(suggestions: viewModel.suggestions, suggestionTapped: viewModel.suggestionTapped(at:))
                    .padding(.top, 26)

                Color.clear
                    .frame(minHeight: containerSize.height - contentSize.height)

                MainButton(
                    title: Localization.commonImport,
                    icon: .leading(Assets.tangemIcon),
                    style: .primary,
                    isLoading: false,
                    isDisabled: !viewModel.isSeedPhraseValid,
                    action: viewModel.importSeedPhrase
                )
                .padding(.vertical, 16)
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
        .onAppear(perform: viewModel.onAppear)
        .onDisappear(perform: viewModel.onDisappear)
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
