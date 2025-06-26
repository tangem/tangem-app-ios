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

    // Backup flow
    case seedPhraseIntro
    case seedPhraseRecovery
    case seedPhraseUserValidation
    case seedPhraseCompleted
}
