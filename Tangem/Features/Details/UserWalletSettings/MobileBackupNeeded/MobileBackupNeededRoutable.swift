//
//  MobileBackupNeededRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

@MainActor
protocol MobileBackupNeededRoutable: AnyObject {
    func openMobileOnboardingFromMobileBackupNeeded(input: MobileOnboardingInput, onBackupFinished: @escaping () -> Void)
    func openMobileBackupTypesFromMobileBackupNeeded(userWalletModel: UserWalletModel)
    func dismissMobileBackupNeeded()
}
