//
//  MobileOnboardingStepsBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import class TangemSdk.BackupService

struct MobileOnboardingStepsBuilder: OnboardingStepsBuilder {
    private let backupService: BackupService

    private var hasUpgradeBiometricsStep: Bool {
        !AppSettings.shared.saveUserWallets && !AppSettings.shared.askedToSaveUserWallets
    }

    init(backupService: BackupService) {
        self.backupService = backupService
    }

    func buildOnboardingSteps() -> OnboardingSteps {
        fatalError("Implementation not required")
    }

    func buildBackupSteps() -> OnboardingSteps? {
        var steps: [WalletOnboardingStep] = []

        steps.append(.mobileUpgradeIntro)

        if backupService.addedBackupCardsCount < BackupService.maxBackupCardsCount {
            steps.append(.selectBackupCards)
        }

        steps.append(.backupCards)

        if hasUpgradeBiometricsStep {
            steps.append(.mobileUpgradeBiometrics)
        }

        return .wallet(steps + [.success])
    }
}
