//
//  MobileOnboardingFlow.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemMobileWalletSdk

enum MobileOnboardingFlow {
    case walletImport(source: MobileOnboardingFlowSource)
    case walletActivate(userWalletModel: UserWalletModel, source: MobileOnboardingFlowSource)
    case accessCode(userWalletModel: UserWalletModel, source: MobileOnboardingFlowSource, context: MobileWalletContext)
    case seedPhraseBackup(userWalletModel: UserWalletModel, source: MobileOnboardingFlowSource)
    case seedPhraseBackupToUpgrade(userWalletModel: UserWalletModel, source: MobileOnboardingFlowSource, onContinue: () -> Void)
    case seedPhraseReveal(context: MobileWalletContext)
}
