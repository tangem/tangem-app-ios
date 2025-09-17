//
//  MobileOnboardingBackupSeedPhraseFlowBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

final class MobileOnboardingBackupSeedPhraseFlowBuilder: MobileOnboardingFlowBuilder {
    private let userWalletModel: UserWalletModel
    private weak var coordinator: MobileOnboardingFlowRoutable?

    init(userWalletModel: UserWalletModel, coordinator: MobileOnboardingFlowRoutable) {
        self.userWalletModel = userWalletModel
        self.coordinator = coordinator
        super.init()
    }

    override func setupFlow() {
        let seedPhraseIntroStep = MobileOnboardingSeedPhraseIntroStep(delegate: self)
            .configureNavBar(
                title: Localization.commonBackup,
                leadingAction: .close(handler: { [weak self] in
                    Analytics.log(.backupNoticeCanceled)

                    self?.closeOnboarding()
                })
            )
        append(step: seedPhraseIntroStep)

        let userWalletId = userWalletModel.userWalletId

        let seedPhraseRecoveryStep = MobileOnboardingSeedPhraseRecoveryStep(userWalletId: userWalletId, delegate: self)
        seedPhraseRecoveryStep.configureNavBar(
            title: Localization.commonBackup,
            leadingAction: navBarBackAction
        )
        append(step: seedPhraseRecoveryStep)

        let seedPhraseValidationStep = MobileOnboardingSeedPhraseValidationStep(userWalletId: userWalletId, delegate: self)
        seedPhraseValidationStep.configureNavBar(
            title: Localization.commonBackup,
            leadingAction: navBarBackAction
        )
        append(step: seedPhraseValidationStep)

        let doneStep = MobileOnboardingSuccessStep(
            type: .seedPhaseBackupFinish,
            onAppear: weakify(self, forFunction: MobileOnboardingBackupSeedPhraseFlowBuilder.openConfetti),
            onComplete: weakify(self, forFunction: MobileOnboardingBackupSeedPhraseFlowBuilder.closeOnboarding)
        )
        doneStep.configureNavBar(title: Localization.commonBackup)
        append(step: doneStep)
    }
}

// MARK: - Navigation

private extension MobileOnboardingBackupSeedPhraseFlowBuilder {
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

// MARK: - MobileOnboardingSeedPhraseIntroDelegate

extension MobileOnboardingBackupSeedPhraseFlowBuilder: MobileOnboardingSeedPhraseIntroDelegate {
    func seedPhraseIntroContinue() {
        openNext()
    }
}

// MARK: - MobileOnboardingSeedPhraseRecoveryDelegate

extension MobileOnboardingBackupSeedPhraseFlowBuilder: MobileOnboardingSeedPhraseRecoveryDelegate {
    func seedPhraseRecoveryContinue() {
        openNext()
    }
}

// MARK: - MobileOnboardingSeedPhraseValidationDelegate

extension MobileOnboardingBackupSeedPhraseFlowBuilder: MobileOnboardingSeedPhraseValidationDelegate {
    func didValidateSeedPhrase() {
        Analytics.log(event: .backupFinished, params: [.cardsCount: String(0)])
        userWalletModel.update(type: .mnemonicBackupCompleted)
        openNext()
    }
}
