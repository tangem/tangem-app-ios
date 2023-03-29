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
    @Published var errorAlert: AlertBinder? = nil

    let inputProcessor: SeedPhraseInputProcessor
    let outputHandler: (Mnemonic) -> Void

    private var bag: Set<AnyCancellable> = []

    init(inputProcessor: SeedPhraseInputProcessor, outputHandler: @escaping (Mnemonic) -> Void) {
        self.inputProcessor = inputProcessor
        self.outputHandler = outputHandler
        bind()
    }

    func importSeedPhrase() {
        guard let validatedPhrase = inputProcessor.validatedSeedPhrase else {
            errorAlert = "Failed to create seed phrase: no valid input".alertBinder
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
    }
}
