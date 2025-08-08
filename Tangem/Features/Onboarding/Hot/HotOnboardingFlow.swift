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
    case walletActivate(userWalletModel: UserWalletModel)
    case accessCodeCreate(userWalletModel: UserWalletModel)
    case accessCodeChange(userWalletModel: UserWalletModel)
    case seedPhraseBackup(userWalletModel: UserWalletModel)
    case seedPhraseReveal(userWalletModel: UserWalletModel)
}
