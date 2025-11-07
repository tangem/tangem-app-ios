//
//  MobileOnboardingFlow.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemMobileWalletSdk

enum MobileOnboardingFlow {
    case walletImport
    case walletActivate(userWalletModel: UserWalletModel)
    case accessCode(userWalletModel: UserWalletModel, context: MobileWalletContext)
    case seedPhraseBackup(userWalletModel: UserWalletModel)
    case seedPhraseBackupToUpgrade(userWalletModel: UserWalletModel, onContinue: () -> Void)
    case seedPhraseReveal(context: MobileWalletContext)
}
