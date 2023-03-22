//
//  OnboardingSeedPhraseImportView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

class OnboardingSeedPhraseImportViewModel: ObservableObject {
    @Published var isSeedPhraseValid: Bool = false
    @Published var inputError: String? = nil
    let inputProcessor: OnboardingSeedPhraseInputProcessor
    let importButtonAction: () -> Void

    private var importButtonSubscription: AnyCancellable?
    private var errorSubscription: AnyCancellable?

    init(inputProcessor: OnboardingSeedPhraseInputProcessor, importButtonAction: @escaping () -> Void) {
        self.inputProcessor = inputProcessor
        self.importButtonAction = importButtonAction
        bind()
    }

    private func bind() {
        importButtonSubscription = inputProcessor.isValidSeedPhrasePublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.isSeedPhraseValid, on: self)

        errorSubscription = inputProcessor.inputErrorPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.inputError, on: self)
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

            if let errorMessage = viewModel.inputError {
                Text(errorMessage)
                    .style(Fonts.Regular.footnote, color: Colors.Text.warning)
                    .padding(.top, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer()

            MainButton(
                title: Localization.commonImport,
                icon: .leading(Assets.tangemIcon),
                style: .primary,
                isLoading: false,
                isDisabled: !viewModel.isSeedPhraseValid,
                action: viewModel.importButtonAction
            )
            .padding(.bottom, 16)
            .keyboardAdaptive()
        }
        .padding(.horizontal, 16)
    }
}

struct OnboardingSeedPhraseImportView_Previews: PreviewProvider {
    private static let manager = CommonOnboardingSeedPhraseManager()
    private static let viewModel = OnboardingSeedPhraseImportViewModel(inputProcessor: manager, importButtonAction: {})

    static var previews: some View {
        OnboardingSeedPhraseImportView(viewModel: viewModel)
    }
}
