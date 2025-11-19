//
//  CreateWalletSelectorRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol CreateWalletSelectorRoutable: AnyObject {
    func openOnboarding(options: OnboardingCoordinator.Options)
    func openMain(userWalletModel: UserWalletModel)
    func openCreateMobileWallet()
    func closeCreateWalletSelector()
}
