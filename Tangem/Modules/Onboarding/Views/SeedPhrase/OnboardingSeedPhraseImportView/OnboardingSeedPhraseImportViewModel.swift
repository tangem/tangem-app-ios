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
    let inputProcessor: OnboardingSeedPhraseInputProcessor
    let importButtonAction: () -> Void

    private var bag: Set<AnyCancellable> = []

    init(inputProcessor: OnboardingSeedPhraseInputProcessor, importButtonAction: @escaping () -> Void) {
        self.inputProcessor = inputProcessor
        self.importButtonAction = importButtonAction
        bind()
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
    }
}
