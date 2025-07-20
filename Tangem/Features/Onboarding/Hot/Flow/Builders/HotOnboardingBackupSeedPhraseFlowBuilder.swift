//
//  HotOnboardingBackupSeedPhraseFlowBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

final class HotOnboardingBackupSeedPhraseFlowBuilder: HotOnboardingFlowBuilder {
    private let userWalletModel: UserWalletModel
    private weak var coordinator: HotOnboardingFlowRoutable?

    init(userWalletModel: UserWalletModel, coordinator: HotOnboardingFlowRoutable) {
        self.userWalletModel = userWalletModel
        self.coordinator = coordinator
        super.init()
    }

    override func setupFlow() {
        let seedPhraseIntroStep = HotOnboardingSeedPhraseIntroStep(delegate: self)
        flow.append(seedPhraseIntroStep)

        let seedPhraseRecoveryStep = HotOnboardingSeedPhraseRecoveryStep(delegate: self)
        flow.append(seedPhraseRecoveryStep)

        let seedPhraseWords = getSeedPhraseWords()
        let seedPhraseValidationStep = HotOnboardingSeedPhraseValidationStep(
            seedPhraseWords: seedPhraseWords,
            onCreateWallet: weakify(self, forFunction: HotOnboardingBackupSeedPhraseFlowBuilder.openNext)
        )
        flow.append(seedPhraseValidationStep)

        let doneStep = HotOnboardingSuccessStep(
            type: .seedPhaseBackupFinish,
            onAppear: weakify(self, forFunction: HotOnboardingBackupSeedPhraseFlowBuilder.openConfetti),
            onComplete: weakify(self, forFunction: HotOnboardingBackupSeedPhraseFlowBuilder.closeOnboarding)
        )
        flow.append(doneStep)
    }
}

// MARK: - Navigation

private extension HotOnboardingBackupSeedPhraseFlowBuilder {
    func openNext() {
        next()
    }

    func openConfetti() {
        coordinator?.openConfetti()
    }

    func closeOnboarding() {
        coordinator?.closeOnboarding()
    }
}

// MARK: - Private methods

private extension HotOnboardingBackupSeedPhraseFlowBuilder {
    func getSeedPhraseWords() -> [String] {
        // [REDACTED_TODO_COMMENT]
        return [
            "brother", "embrace", "piano", "income", "feature", "real",
            "bicycle", "stairs", "glimpse", "fan", "salon", "elder",
            // brother embrace piano income feature real bicycle stairs glimpse fan salon elder
        ]
    }
}

// MARK: - HotOnboardingSeedPhraseIntroDelegate

extension HotOnboardingBackupSeedPhraseFlowBuilder: HotOnboardingSeedPhraseIntroDelegate {
    func seedPhraseIntroContinue() {
        openNext()
    }
}

// MARK: - HotOnboardingSeedPhraseRecoveryDelegate

extension HotOnboardingBackupSeedPhraseFlowBuilder: HotOnboardingSeedPhraseRecoveryDelegate {
    func getSeedPhrase() -> [String] {
        getSeedPhraseWords()
    }

    func seedPhraseRecoveryContinue() {
        openNext()
    }
}
