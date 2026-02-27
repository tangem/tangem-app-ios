//
//  MobileCreateWalletRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

@MainActor
protocol MobileCreateWalletRoutable: AnyObject {
    func openMobileOnboarding(input: MobileOnboardingInput)
    func closeMobileCreateWallet()
}
