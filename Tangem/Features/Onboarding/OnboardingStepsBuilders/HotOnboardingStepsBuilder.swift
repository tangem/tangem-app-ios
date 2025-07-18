//
//  HotOnboardingStepsBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct HotOnboardingStepsBuilder {
    @Injected(\.pushNotificationsInteractor) private var pushNotificationsInteractor: PushNotificationsInteractor

    func buildSteps(flow: HotOnboardingFlow) -> [HotOnboardingStep] {
        switch flow {
        case .walletCreate:
            buildWalletCreateSteps()
        case .walletImport:
            buildWalletImportSteps()
        case .walletActivate:
            buildWalletActivateSteps()
        case .accessCodeCreate:
            buildAccessCodeCreateSteps()
        case .accessCodeChange(let needAccessCodeValidation):
            buildAccessCodeChangeSteps(needAccessCodeValidation: needAccessCodeValidation)
        case .seedPhraseBackup:
            buildSeedPhraseBackupSteps()
        case .seedPhraseReveal(let needAccessCodeValidation):
            buildSeedPhraseRevealSteps(needAccessCodeValidation: needAccessCodeValidation)
        }
    }
}

private extension HotOnboardingStepsBuilder {
    func buildWalletCreateSteps() -> [HotOnboardingStep] {
        [.createWallet]
    }

    func buildWalletImportSteps() -> [HotOnboardingStep] {
        var steps: [HotOnboardingStep] = [.importSeedPhrase, .importCompleted, .accessCodeCreate]

        let factory = PushNotificationsHelpersFactory()
        let availabilityProvider = factory.makeAvailabilityProviderForWalletOnboarding(using: pushNotificationsInteractor)

        if availabilityProvider.isAvailable {
            steps.append(.pushNotifications)
        }

        steps.append(.done)

        return steps
    }

    func buildWalletActivateSteps() -> [HotOnboardingStep] {
        [.seedPhraseIntro, .seedPhraseRecovery, .seedPhraseValidate, .seedPhaseBackupContinue] +
            [.accessCodeCreate, .done]
    }

    func buildSeedPhraseBackupSteps() -> [HotOnboardingStep] {
        [.seedPhraseIntro, .seedPhraseRecovery, .seedPhraseValidate, .seedPhaseBackupFinish]
    }

    func buildAccessCodeCreateSteps() -> [HotOnboardingStep] {
        [.accessCodeCreate, .done]
    }

    func buildAccessCodeChangeSteps(needAccessCodeValidation: Bool) -> [HotOnboardingStep] {
        let validationStep: HotOnboardingStep? = needAccessCodeValidation ? .accessCodeValidate : nil
        return [validationStep, .accessCodeCreate].compactMap { $0 }
    }

    func buildSeedPhraseRevealSteps(needAccessCodeValidation: Bool) -> [HotOnboardingStep] {
        let validationStep: HotOnboardingStep? = needAccessCodeValidation ? .accessCodeValidate : nil
        return [validationStep, .seedPhraseReveal].compactMap { $0 }
    }
}
