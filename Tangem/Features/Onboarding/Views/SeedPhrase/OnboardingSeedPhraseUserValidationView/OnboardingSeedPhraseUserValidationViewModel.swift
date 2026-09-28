//
//  OnboardingSeedPhraseUserValidationViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemLocalization
import TangemUI
import TangemAssets

class OnboardingSeedPhraseUserValidationViewModel: ObservableObject {
    struct ValidationInput {
        let secondWord: String
        let seventhWord: String
        let eleventhWord: String
        /// Offer the optional BIP-39 passphrase toggle (wallet *creation* only; the mobile flow validates
        /// an already created wallet and must not show it).
        let allowsPassphrase: Bool
        /// `passphrase` is `nil` unless the user opted in and typed a valid, confirmed passphrase.
        let createWalletAction: (_ passphrase: String?) -> Void

        init(
            secondWord: String,
            seventhWord: String,
            eleventhWord: String,
            allowsPassphrase: Bool = false,
            createWalletAction: @escaping (_ passphrase: String?) -> Void
        ) {
            self.secondWord = secondWord
            self.seventhWord = seventhWord
            self.eleventhWord = eleventhWord
            self.allowsPassphrase = allowsPassphrase
            self.createWalletAction = createWalletAction
        }
    }

    @Published var firstInputText = ""
    @Published var secondInputText = ""
    @Published var thirdInputText = ""
    @Published var firstInputHasError = false
    @Published var secondInputHasError = false
    @Published var thirdInputHasError = false

    @Published var isCreateWalletButtonEnabled = false

    /// Present only when `ValidationInput.allowsPassphrase` is set.
    let passphraseSetupViewModel: OnboardingSeedPassphraseSetupViewModel?

    var actionTitle: String {
        switch mode {
        case .mobile: Localization.commonContinue
        case .card: Localization.onboardingCreateWalletButtonCreateWallet
        }
    }

    var actionIcon: MainButton.Icon? {
        switch mode {
        case .mobile: nil
        case .card: MainButton.Icon.trailing(Assets.tangemIcon)
        }
    }

    private let mode: Mode
    private let input: ValidationInput
    /// Mirrors `passphraseSetupViewModel.isValid`; `@Published` emits before the property is written, so the
    /// latest value is taken from the stream rather than read back from the child view model.
    private var isPassphraseValid = true
    private var bag: Set<AnyCancellable> = []

    init(mode: Mode, validationInput: ValidationInput) {
        self.mode = mode
        input = validationInput
        passphraseSetupViewModel = validationInput.allowsPassphrase
            ? OnboardingSeedPassphraseSetupViewModel(showsMobileUpgradeNote: mode == .mobile)
            : nil

        bind()
    }

    func createWallet() {
        input.createWalletAction(passphraseSetupViewModel?.resolvedPassphrase)
    }

    private func bind() {
        subscribeToInputUpdates(to: \.$firstInputText, errorKeyParh: \.firstInputHasError, targetWord: input.secondWord, on: self)
        subscribeToInputUpdates(to: \.$secondInputText, errorKeyParh: \.secondInputHasError, targetWord: input.seventhWord, on: self)
        subscribeToInputUpdates(to: \.$thirdInputText, errorKeyParh: \.thirdInputHasError, targetWord: input.eleventhWord, on: self)

        passphraseSetupViewModel?.$isValid
            .removeDuplicates()
            .sink { [weak self] isPassphraseValid in
                self?.isPassphraseValid = isPassphraseValid
                self?.updateButtonState()
            }
            .store(in: &bag)
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
            .map { [weak root] newText in
                root?[keyPath: errorKeyParh] = false
                return newText
            }
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .sink { _ in } receiveValue: { [weak self, weak root] newText in
                if !newText.isEmpty,
                   newText != targetWord {
                    root?[keyPath: errorKeyParh] = true
                }

                self?.updateButtonState()
            }
            .store(in: &bag)
    }

    private func updateButtonState() {
        let wordsMatch = firstInputText == input.secondWord &&
            secondInputText == input.seventhWord &&
            thirdInputText == input.eleventhWord

        isCreateWalletButtonEnabled = wordsMatch && isPassphraseValid
    }
}

// MARK: - Types

extension OnboardingSeedPhraseUserValidationViewModel {
    /// Represents the UI mode for seed phrase validation.
    enum Mode {
        /// Validation performed using a Tangem card.
        case card
        /// Validation performed using a mobile device only.
        case mobile
    }
}
