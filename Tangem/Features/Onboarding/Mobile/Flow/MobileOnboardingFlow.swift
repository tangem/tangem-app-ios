//
//  MobileOnboardingFlow.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemMobileWalletSdk
import TangemMobileWalletBackup

enum MobileOnboardingFlow {
    case walletImport(source: MobileOnboardingFlowSource)

    case walletActivate(
        userWalletModel: UserWalletModel,
        source: MobileOnboardingFlowSource,
        context: MobileWalletContext
    )

    case accessCode(
        userWalletModel: UserWalletModel,
        source: MobileOnboardingFlowSource,
        context: MobileWalletContext
    )

    case seedPhraseBackup(
        userWalletModel: UserWalletModel,
        source: MobileOnboardingFlowSource,
        context: MobileWalletContext
    )

    case seedPhraseReveal(context: MobileWalletContext)

    case iCloudBackup(
        userWalletModel: UserWalletModel,
        source: MobileOnboardingFlowSource
    )

    case iCloudBackupImport(
        backups: [MobileWalletBackup],
        source: MobileOnboardingFlowSource
    )
}
