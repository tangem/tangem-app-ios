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
        source: MobileOnboardingFlowSource,
        coordinator: MobileOnboardingFlowRoutable,
        onContinue: @escaping () -> Void
    ) {
        self.onContinue = onContinue
        super.init(userWalletModel: userWalletModel, source: source, coordinator: coordinator)
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
            navigationTitle: Localization.commonBackup,
            onAppear: { [weak self] in
                self?.logBackupCompletedScreenOpenedAnalytics()
            },
            onComplete: weakify(self, forFunction: MobileOnboardingBackupToUpgradeSeedPhraseFlowBuilder.didContinue)
        )
        return step
    }

    func didContinue() {
        onContinue()
    }
}
