//
//  MobileBackupTypesRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol MobileBackupTypesRoutable: AnyObject {
    func openMobileUpgrade(userWalletModel: UserWalletModel)
    func openMobileOnboarding(input: MobileOnboardingInput)
}
