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

    func openMobileBackupNeeded(userWalletModel: UserWalletModel, source: MobileOnboardingFlowSource, onBackupFinished: @escaping () -> Void)
    func openMobileBackupTypes(userWalletModel: UserWalletModel)
    func openMobileRemoveWalletNotification(userWalletModel: UserWalletModel)

    @MainActor
    func openHardwareBackupTypes(userWalletModel: UserWalletModel)

    @MainActor
    func closeOnboarding()

    func openAppSettings()

    func dismiss()
}
