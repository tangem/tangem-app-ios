//
//  HardwareBackupTypesRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemMobileWalletSdk

@MainActor
protocol HardwareBackupTypesRoutable: AnyObject {
    func openCreateHardwareWallet(userWalletModel: UserWalletModel)
    func openMobileOnboarding(input: MobileOnboardingInput)
    func openUpgradeToHardwareWallet(userWalletModel: UserWalletModel, context: MobileWalletContext)
    func openMobileBackupNeeded(userWalletModel: UserWalletModel, source: MobileOnboardingFlowSource, onBackupFinished: @escaping () -> Void)
    func closeOnboarding()
}
