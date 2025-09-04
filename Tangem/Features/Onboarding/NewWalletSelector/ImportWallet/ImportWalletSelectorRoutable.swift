//
//  ImportWalletSelectorRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol ImportWalletSelectorRoutable: AnyObject {
    func openOnboarding(options: OnboardingCoordinator.Options)
    func openMain(userWalletModel: UserWalletModel)
}
