//
//  MobileBackupToUpgradeNeededRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

@MainActor
protocol MobileBackupToUpgradeNeededRoutable: AnyObject {
    func openMobileOnboardingFromMobileBackupToUpgradeNeeded(input: MobileOnboardingInput, onBackupFinished: @escaping () -> Void)
    func dismissMobileBackupToUpgradeNeeded()
}
