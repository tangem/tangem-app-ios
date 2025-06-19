//
//  HotOnboardingStepsBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct HotOnboardingStepsBuilder {
    func buildCreationSteps() -> [HotOnboardingStep] {
        [.createWallet]
    }

    func buildImportingSteps() -> [HotOnboardingStep] {
        [.importWallet]
    }

    func buildBackupSteps() -> [HotOnboardingStep] {
        []
    }
}
