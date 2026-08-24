//
//  WelcomeV2Routable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol WelcomeV2Routable: AnyObject {
    func openCreateWallet()
    func openExistingWallet()
    func openHardwareWallet()
    func closeHardwareWallet()
    func openLegal(url: URL)
    func openMain(with userWalletModel: UserWalletModel)
    func openOnboarding(with input: OnboardingInput)
}
