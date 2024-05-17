//
//  UserWalletSettingsRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol UserWalletSettingsRoutable: AnyObject {
    func openWalletConnect(with disabledLocalizedReason: String?)
    func openOnboardingModal(with input: OnboardingInput)

    func openScanCardSettings(with cardScanner: CardScanner)
    func openDisclaimer(at url: URL)
    func openReferral(input: ReferralInputModel)
}
