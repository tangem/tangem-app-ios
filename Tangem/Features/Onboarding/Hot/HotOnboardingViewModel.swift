//
//  HotOnboardingViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk

final class HotOnboardingViewModel: ObservableObject {
    @Published var currentStep: HotOnboardingStep

    @Published var shouldFireConfetti: Bool = false

    let navigationBarHeight = OnboardingLayoutConstants.navbarSize.height
    let progressBarHeight = OnboardingLayoutConstants.progressBarHeight

    lazy var createWalletViewModel = HotOnboardingCreateWalletViewModel(delegate: self)
    lazy var importWalletViewModel = HotOnboardingImportWalletViewModel(delegate: self)
    lazy var seedPhraseIntroViewModel = HotOnboardingSeedPhraseIntroViewModel(delegate: self)
    lazy var seedPhraseCompletedViewModel = HotOnboardingSeedPhraseCompletedViewModel(delegate: self)

    var seedPhraseRecoveryViewModel: HotOnboardingSeedPhraseRecoveryViewModel?
    var seedPhraseUserValidationViewModel: OnboardingSeedPhraseUserValidationViewModel?

    var navigationBarTitle: String {
        switch currentStep {
        case .createWallet:
            ""
        case .importWallet:
            "Import wallet"
        case .seedPhraseIntro, .seedPhraseRecovery, .seedPhraseUserValidation, .seedPhraseCompleted:
            "Backup"
        }
    }

    var leadingButtonStyle: LeadingButtonStyle {
        switch currentStep {
        case .createWallet, .importWallet:
            return .back
        case .seedPhraseIntro:
            return .close
        case .seedPhraseRecovery, .seedPhraseUserValidation:
            return .back
        case .seedPhraseCompleted:
            return .none
        }
    }

    var isProgressBarEnabled: Bool {
        switch currentStep {
        case .createWallet, .importWallet:
            false
        case .seedPhraseIntro, .seedPhraseRecovery, .seedPhraseUserValidation, .seedPhraseCompleted:
            true
        }
    }

    var currentProgress: CGFloat {
        let currentStepIndex = input.steps.firstIndex(of: currentStep) ?? 0
        return CGFloat(currentStepIndex + 1) / CGFloat(input.steps.count)
    }

    private let input: HotOnboardingInput
    private weak var coordinator: HotOnboardingRoutable?

    init(input: HotOnboardingInput, coordinator: HotOnboardingRoutable) {
        self.input = input
        self.coordinator = coordinator
        currentStep = input.steps.first ?? .createWallet
    }
}

// MARK: - Internal methods

extension HotOnboardingViewModel {
    func backButtonAction() {
        switch currentStep {
        case .createWallet, .importWallet:
            closeOnboarding()
        case .seedPhraseIntro, .seedPhraseCompleted:
            break
        case .seedPhraseRecovery:
            goToStep(.seedPhraseIntro)
        case .seedPhraseUserValidation:
            goToStep(.seedPhraseRecovery)
        }
    }

    func onCloseTap() {
        closeOnboarding()
    }
}

// MARK: - Steps navigation

private extension HotOnboardingViewModel {
    func goToStep(_ step: HotOnboardingStep) {
        currentStep = step
    }
}

// MARK: - Private methods

private extension HotOnboardingViewModel {
    func getSeedPhraseWords() -> [String] {
        // [REDACTED_TODO_COMMENT]
        return [
            "saddle", "beauty", "myth", "loyal", "fluid", "exotic",
            "snow", "fantasy", "relief", "pillar", "coconut", "crowd",
        ]
    }

    func closeOnboarding() {
        coordinator?.closeOnboarding()
    }
}

// MARK: - HotOnboardingCreateWalletDelegate

extension HotOnboardingViewModel: HotOnboardingCreateWalletDelegate {
    func onCreateWallet() {
        // [REDACTED_TODO_COMMENT]
    }
}

// MARK: - HotOnboardingImportWalletDelegate

extension HotOnboardingViewModel: HotOnboardingImportWalletDelegate {
    func importSeedPhrase(mnemonic: Mnemonic, passphrase: String?) {
        // [REDACTED_TODO_COMMENT]
    }
}

// MARK: - HotOnboardingSeedPhraseIntroDelegate

extension HotOnboardingViewModel: HotOnboardingSeedPhraseIntroDelegate {
    func seedPhraseIntroContinue() {
        let seedPhraseWords = getSeedPhraseWords()
        seedPhraseRecoveryViewModel = HotOnboardingSeedPhraseRecoveryViewModel(
            seedPhrase: .init(words: seedPhraseWords),
            delegate: self
        )
        goToStep(.seedPhraseRecovery)
    }
}

// MARK: - HotOnboardingSeedPhraseRecoveryDelegate

extension HotOnboardingViewModel: HotOnboardingSeedPhraseRecoveryDelegate {
    func seedPhraseRecoveryContinue() {
        let seedPhraseWords = getSeedPhraseWords()

        seedPhraseUserValidationViewModel = OnboardingSeedPhraseUserValidationViewModel(validationInput: .init(
            secondWord: seedPhraseWords[1],
            seventhWord: seedPhraseWords[6],
            eleventhWord: seedPhraseWords[10],
            createWalletAction: { [weak self] in
                self?.goToStep(.seedPhraseCompleted)
            }
        ))

        goToStep(.seedPhraseUserValidation)
    }
}

// MARK: - HotOnboardingSeedPhraseCompletedDelegate

extension HotOnboardingViewModel: HotOnboardingSeedPhraseCompletedDelegate {
    func seedPhraseCompletedContinue() {}
}

// MARK: - Types

extension HotOnboardingViewModel {
    enum LeadingButtonStyle {
        case back
        case close
        case none
    }
}
