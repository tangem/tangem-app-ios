//
//  MobileBackupTypesRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemMobileWalletSdk

protocol MobileBackupTypesRoutable: AnyObject {
    func openMobileOnboarding(input: MobileOnboardingInput)
    func openMobileUpgrade(userWalletModel: UserWalletModel, context: MobileWalletContext)
}
