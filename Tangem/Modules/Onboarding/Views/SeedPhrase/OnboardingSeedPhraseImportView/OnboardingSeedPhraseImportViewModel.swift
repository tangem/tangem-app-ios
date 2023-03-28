//
//  OnboardingSeedPhraseImportViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class OnboardingSeedPhraseImportViewModel: ObservableObject {
    @Published var isSeedPhraseValid: Bool = false
    @Published var inputError: String? = nil
    @Published var suggestions: [String] = []
    let inputProcessor: SeedPhraseInputProcessor
    let importButtonAction: () -> Void

    private var bag: Set<AnyCancellable> = []

    init(inputProcessor: SeedPhraseInputProcessor, importButtonAction: @escaping () -> Void) {
        self.inputProcessor = inputProcessor
        self.importButtonAction = importButtonAction
        bind()
    }

    func tappedSuggestion(at index: Int) {
        AppLog.shared.debug("[Seed onboarding] Tap on suggestion bubble: \(suggestions[index])")
        inputProcessor.insertSuggestion(suggestions[index])
    }

    private func bind() {
        inputProcessor.isSeedPhraseValidPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.isSeedPhraseValid, on: self)
            .store(in: &bag)

        inputProcessor.inputErrorPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.inputError, on: self)
            .store(in: &bag)

        inputProcessor.suggestionsPublisher
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.suggestions, on: self)
            .store(in: &bag)
    }
}
