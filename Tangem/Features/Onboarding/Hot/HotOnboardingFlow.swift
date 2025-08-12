//
//  HotOnboardingFlow.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemHotSdk

enum HotOnboardingFlow {
    case walletCreate
    case walletImport
    case walletActivate(userWalletModel: UserWalletModel)
    case accessCode(userWalletModel: UserWalletModel, context: MobileWalletContext)
    case seedPhraseBackup(userWalletModel: UserWalletModel)
    case seedPhraseReveal(userWalletModel: UserWalletModel)
}
