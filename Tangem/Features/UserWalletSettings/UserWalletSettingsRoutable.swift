//
//  UserWalletSettingsRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemMobileWalletSdk

protocol UserWalletSettingsRoutable: AnyObject, TransactionNotificationsRowToggleRoutable, UserSettingsAccountsRoutable {
    func openOnboardingModal(with options: OnboardingCoordinator.Options)

    func openScanCardSettings(with input: ScanCardSettingsViewModel.Input)
    func openReferral(input: ReferralInputModel)

    func openManageTokens(
        walletModelsManager: WalletModelsManager,
        userTokensManager: UserTokensManager,
        userWalletConfig: UserWalletConfig
    )

    func openMobileBackupNeeded(userWalletModel: UserWalletModel)
    func openMobileBackupTypes(userWalletModel: UserWalletModel)
    func openMobileUpgrade(userWalletModel: UserWalletModel)
    func openMobileRemoveWalletNotification(userWalletModel: UserWalletModel)

    func openAppSettings()

    func dismiss()
}
