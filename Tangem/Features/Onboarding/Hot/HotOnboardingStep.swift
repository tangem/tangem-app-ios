//
//  HotOnboardingStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemLocalization

enum HotOnboardingStep {
    /// Create flow
    case createWallet

    /// Import flow
    case importSeedPhrase
    case importCompleted

    /// Seed phrase flow
    case seedPhraseIntro
    case seedPhraseRecovery
    case seedPhraseValidate
    case seedPhraseReveal
    case seedPhaseBackupContinue
    case seedPhaseBackupFinish

    /// Access code flow
    case accessCodeCreate
    case accessCodeValidate

    /// Others
    case pushNotifications
    case done
}
