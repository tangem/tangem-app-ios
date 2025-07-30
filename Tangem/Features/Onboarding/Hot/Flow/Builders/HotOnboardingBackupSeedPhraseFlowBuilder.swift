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
        flow.append(seedPhraseIntroStep)

        let seedPhraseResolver = CommonHotOnboardingSeedPhraseResolver(userWalletModel: userWalletModel)

        let seedPhraseRecoveryStep = HotOnboardingSeedPhraseRecoveryStep(
            seedPhraseResolver: seedPhraseResolver,
            delegate: self
        )
        .configureNavBar(
            title: Localization.commonBackup,
            leadingAction: navBarBackAction
        )
        flow.append(seedPhraseRecoveryStep)

        let seedPhraseValidationStep = HotOnboardingSeedPhraseValidationStep(
            seedPhraseResolver: seedPhraseResolver,
            onCreateWallet: weakify(self, forFunction: HotOnboardingBackupSeedPhraseFlowBuilder.openNext)
        )
        seedPhraseValidationStep.configureNavBar(
            title: Localization.commonBackup,
            leadingAction: navBarBackAction
        )
        flow.append(seedPhraseValidationStep)

        let doneStep = HotOnboardingSuccessStep(
            type: .seedPhaseBackupFinish,
            onAppear: weakify(self, forFunction: HotOnboardingBackupSeedPhraseFlowBuilder.openConfetti),
            onComplete: weakify(self, forFunction: HotOnboardingBackupSeedPhraseFlowBuilder.closeOnboarding)
        )
        doneStep.configureNavBar(title: Localization.commonBackup)
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
