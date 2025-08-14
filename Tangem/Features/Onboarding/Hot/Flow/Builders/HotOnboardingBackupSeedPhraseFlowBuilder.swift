//
//  HotOnboardingBackupSeedPhraseFlowBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

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
            .configureNavBar(
                title: Localization.commonBackup,
                leadingAction: .close(handler: { [weak self] in
                    self?.closeOnboarding()
                })
            )
        append(step: seedPhraseIntroStep)

        let userWalletId = userWalletModel.userWalletId

        let seedPhraseRecoveryStep = HotOnboardingSeedPhraseRecoveryStep(userWalletId: userWalletId, delegate: self)
        seedPhraseRecoveryStep.configureNavBar(
            title: Localization.commonBackup,
            leadingAction: navBarBackAction
        )
        append(step: seedPhraseRecoveryStep)

        let seedPhraseValidationStep = HotOnboardingSeedPhraseValidationStep(userWalletId: userWalletId, delegate: self)
        seedPhraseValidationStep.configureNavBar(
            title: Localization.commonBackup,
            leadingAction: navBarBackAction
        )
        append(step: seedPhraseValidationStep)

        let doneStep = HotOnboardingSuccessStep(
            type: .seedPhaseBackupFinish,
            onAppear: weakify(self, forFunction: HotOnboardingBackupSeedPhraseFlowBuilder.openConfetti),
            onComplete: weakify(self, forFunction: HotOnboardingBackupSeedPhraseFlowBuilder.closeOnboarding)
        )
        doneStep.configureNavBar(title: Localization.commonBackup)
        append(step: doneStep)
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

// MARK: - HotOnboardingSeedPhraseIntroDelegate

extension HotOnboardingBackupSeedPhraseFlowBuilder: HotOnboardingSeedPhraseIntroDelegate {
    func seedPhraseIntroContinue() {
        openNext()
    }
}

// MARK: - HotOnboardingSeedPhraseRecoveryDelegate

extension HotOnboardingBackupSeedPhraseFlowBuilder: HotOnboardingSeedPhraseRecoveryDelegate {
    func seedPhraseRecoveryContinue() {
        openNext()
    }
}

// MARK: - HotOnboardingSeedPhraseValidationDelegate

extension HotOnboardingBackupSeedPhraseFlowBuilder: HotOnboardingSeedPhraseValidationDelegate {
    func didValidateSeedPhrase() {
        userWalletModel.update(type: .mnemonicBackupCompleted)
        openNext()
    }
}
