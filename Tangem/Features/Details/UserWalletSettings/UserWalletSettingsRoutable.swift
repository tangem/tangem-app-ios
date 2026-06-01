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

    func openNotificationSettings(userWalletModel: UserWalletModel)

    func openMobileBackupNeeded(userWalletModel: UserWalletModel, source: MobileOnboardingFlowSource, onBackupFinished: @escaping () -> Void)
    func openMobileBackupTypes(userWalletModel: UserWalletModel)
    func openMobileRemoveWalletNotification(userWalletModel: UserWalletModel)

    @MainActor
    func openHardwareBackupTypes(userWalletModel: UserWalletModel)

    @MainActor
    func closeOnboarding()

    func openAppSettings()

    func dismiss()

    /// Unfortunately, we can't just observe `rootViewModel.alert` to process pending navigation steps when alert is dismissed,
    /// because it becomes `nil` earlier than actual alert dismissal happens. Therefore this method should be called on
    /// every alert dismissal in the root view model.
    func onAlertDismiss()
}
