//
//  MobileOnboardingBackupToUpgradeSeedPhraseFlowBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

final class MobileOnboardingBackupToUpgradeSeedPhraseFlowBuilder: MobileOnboardingBackupSeedPhraseFlowBuilder {
    private let onContinue: () -> Void

    init(
        userWalletModel: UserWalletModel,
        coordinator: MobileOnboardingFlowRoutable,
        onContinue: @escaping () -> Void
    ) {
        self.onContinue = onContinue
        super.init(userWalletModel: userWalletModel, coordinator: coordinator)
    }

    override func completeStep() -> Step {
        makeContinueStep()
    }
}

// MARK: - Private methods

private extension MobileOnboardingBackupToUpgradeSeedPhraseFlowBuilder {
    func makeContinueStep() -> Step {
        let step = MobileOnboardingSuccessStep(
            type: .seedPhaseBackupContinue,
            onAppear: {},
            onComplete: weakify(self, forFunction: MobileOnboardingBackupToUpgradeSeedPhraseFlowBuilder.didContinue)
        )
        step.configureNavBar(title: Localization.commonBackup)
        return step
    }

    func didContinue() {
        onContinue()
    }
}
