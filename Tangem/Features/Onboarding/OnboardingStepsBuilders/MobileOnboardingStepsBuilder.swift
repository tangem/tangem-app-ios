//
//  MobileOnboardingStepsBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct MobileOnboardingStepsBuilder: OnboardingStepsBuilder {
    private let backupService: UserWalletBackupService

    private let commonStepsBuilder = CommonOnboardingStepsBuilder()

    init(backupService: UserWalletBackupService) {
        self.backupService = backupService
    }

    func buildOnboardingSteps() -> OnboardingSteps {
        fatalError("Implementation not required")
    }

    func buildBackupSteps() -> OnboardingSteps? {
        var steps: [WalletOnboardingStep] = []

        steps.append(.mobileUpgradeIntro)

        if backupService.addedBackupCardsCount < UserWalletBackupService.maxBackupCardsCount {
            steps.append(.selectBackupCards)
        }

        steps.append(.backupCards)

        if commonStepsBuilder.shouldAddSaveWalletsStep {
            steps.append(.mobileUpgradeBiometrics)
        }

        return .wallet(steps + [.success])
    }
}
