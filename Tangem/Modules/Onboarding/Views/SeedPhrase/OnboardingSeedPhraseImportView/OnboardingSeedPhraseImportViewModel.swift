//
//  OnboardingSeedPhraseImportViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk

class OnboardingSeedPhraseImportViewModel: ObservableObject {
    @Published var isSeedPhraseValid: Bool = false
    @Published var inputError: String? = nil
    @Published var suggestions: [String] = []
    @Published var errorAlert: AlertBinder? = nil

    let inputProcessor: SeedPhraseInputProcessor
    let outputHandler: (Mnemonic) -> Void

    private var bag: Set<AnyCancellable> = []

    init(inputProcessor: SeedPhraseInputProcessor, outputHandler: @escaping (Mnemonic) -> Void) {
        self.inputProcessor = inputProcessor
        self.outputHandler = outputHandler
        bind()
    }

    func suggestionTapped(at index: Int) {
        inputProcessor.insertSuggestion(suggestions[index])
    }

    func onAppear() {
        UIScrollView.appearance().keyboardDismissMode = .none
    }

    func onDisappear() {
        UIScrollView.appearance().keyboardDismissMode = AppConstants.defaultScrollViewKeyboardDismissMode
    }

    func importSeedPhrase() {
        guard let validatedPhrase = inputProcessor.validatedSeedPhrase else {
            return
        }

        do {
            let mnemonic = try Mnemonic(with: validatedPhrase)
            outputHandler(mnemonic)
        } catch {
            AppLog.shared.debug("[Seed Phrase] Failed to generate seed phrase using input. Error: \(error)")
            errorAlert = error.alertBinder
        }
    }

    private func bind() {
        inputProcessor.isSeedPhraseValidPublisher
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.isSeedPhraseValid, on: self)
            .store(in: &bag)

        inputProcessor.$inputError
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.inputError, on: self)
            .store(in: &bag)

        inputProcessor.$suggestions
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.suggestions, on: self)
            .store(in: &bag)
    }
}
