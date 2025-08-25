//
//  HotOnboardingFlow.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

enum HotOnboardingFlow {
    case walletCreate
    case walletImport
    case walletActivate
    case accessCodeCreate
    case accessCodeChange(needAccessCodeValidation: Bool)
    case seedPhraseBackup
    case seedPhraseReveal(needAccessCodeValidation: Bool)
}
