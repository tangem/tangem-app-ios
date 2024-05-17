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

    func openCardSettings(with input: CardSettingsViewModel.Input)
    func openReferral(input: ReferralInputModel)
    func dismiss()
}
