//
//  UserWalletSettingsRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol UserWalletSettingsRoutable: AnyObject, TransactionNotificationsRowToggleRoutable {
    func openAddNewAccount()
    func openOnboardingModal(with options: OnboardingCoordinator.Options)

    func openScanCardSettings(with input: ScanCardSettingsViewModel.Input)
    func openReferral(input: ReferralInputModel)
    func openManageTokens(userWalletModel: UserWalletModel)

    func openHotBackupNeeded(userWalletModel: UserWalletModel)
    func openHotBackupTypes(userWalletModel: UserWalletModel)

    func openAppSettings()

    func dismiss()
}
