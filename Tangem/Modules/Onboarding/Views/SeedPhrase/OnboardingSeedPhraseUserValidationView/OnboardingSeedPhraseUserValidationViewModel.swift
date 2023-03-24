//
//  OnboardingSeedPhraseUserValidationViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class OnboardingSeedPhraseUserValidationViewModel: ObservableObject {
    struct ValidationInput {
        let secondWord: String
        let seventhWord: String
        let eleventhWord: String
        let createWalletAction: () -> Void
    }

    @Published var firstInputText: String = ""
    @Published var secondInputText: String = ""
    @Published var thirdInputText: String = ""
    @Published var isFirstInputWithError: Bool = false
    @Published var isSecondInputWithError: Bool = false
    @Published var isThirdInputWithError: Bool = false

    @Published var isCreateWalletButtonEnabled = false

    private let input: ValidationInput
    private var bag: Set<AnyCancellable> = []

    init(validationInput: ValidationInput) {
        input = validationInput

        bind()
    }

    func createWallet() {
        input.createWalletAction()
    }

    private func bind() {
        subscribeToInputUpdates(to: \.$firstInputText, errorKeyParh: \.isFirstInputWithError, targetWord: input.secondWord, on: self)
        subscribeToInputUpdates(to: \.$secondInputText, errorKeyParh: \.isSecondInputWithError, targetWord: input.seventhWord, on: self)
        subscribeToInputUpdates(to: \.$thirdInputText, errorKeyParh: \.isThirdInputWithError, targetWord: input.eleventhWord, on: self)
    }

    private func subscribeToInputUpdates(
        to inputKeyPath: KeyPath<OnboardingSeedPhraseUserValidationViewModel, Published<String>.Publisher>,
        errorKeyParh: ReferenceWritableKeyPath<OnboardingSeedPhraseUserValidationViewModel, Bool>,
        targetWord: String,
        on root: OnboardingSeedPhraseUserValidationViewModel
    ) {
        root[keyPath: inputKeyPath]
            .dropFirst()
            .removeDuplicates()
            .map { newText in
                root[keyPath: errorKeyParh] = false
                return newText
            }
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .sink { _ in } receiveValue: { [weak self] newText in
                if !newText.isEmpty,
                   newText != targetWord {
                    root[keyPath: errorKeyParh] = true
                }

                self?.updateButtonState()
            }
            .store(in: &bag)
    }

    private func updateButtonState() {
        let isContainErrors = isFirstInputWithError && isSecondInputWithError && isThirdInputWithError
        isCreateWalletButtonEnabled = !isContainErrors && isAllWordsValid()
    }

    private func isAllWordsValid() -> Bool {
        if firstInputText != input.secondWord {
            return false
        }

        if secondInputText != input.seventhWord {
            return false
        }

        if thirdInputText != input.eleventhWord {
            return false
        }

        return true
    }
}
