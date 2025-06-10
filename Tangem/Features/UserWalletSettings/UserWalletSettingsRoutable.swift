//
//  UserWalletSettingsRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol UserWalletSettingsRoutable: AnyObject {
    func openAddNewAccount()
    func openOnboardingModal(with input: OnboardingInput)

    func openScanCardSettings(with input: ScanCardSettingsViewModel.Input)
    func openReferral(input: ReferralInputModel)
    func openManageTokens(userWalletModel: UserWalletModel)
    func dismiss()
}
