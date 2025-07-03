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

    func buildImportSteps(isPushNotificationsAvailable: Bool) -> [HotOnboardingStep] {
        let pushNotificationsSteps: [HotOnboardingStep] = isPushNotificationsAvailable ? [.pushNotifications] : []
        return [.importWallet, .importCompleted] + buildAccessCodeSteps() + pushNotificationsSteps + [.done]
    }

    func buildBackupSteps() -> [HotOnboardingStep] {
        buildSeedPhraseSteps() + buildAccessCodeSteps() + [.done]
    }

    func buildSeedPhraseSteps() -> [HotOnboardingStep] {
        [.seedPhraseIntro, .seedPhraseRecovery, .seedPhraseUserValidation, .seedPhraseCompleted]
    }

    func buildAccessCodeSteps() -> [HotOnboardingStep] {
        [.checkAccessCode, .accessCode]
    }
}
