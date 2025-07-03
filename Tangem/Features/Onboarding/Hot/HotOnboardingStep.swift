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
    case importWallet
    case importCompleted

    /// Seed phrase flow
    case seedPhraseIntro
    case seedPhraseRecovery
    case seedPhraseUserValidation
    case seedPhraseCompleted

    /// Access code flow
    case checkAccessCode
    case accessCode

    /// Others
    case pushNotifications
    case done
}
