//
//  MobileOnboardingRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

@MainActor
protocol MobileOnboardingRoutable: OnboardingRoutable {
    func mobileOnboardingDidComplete()
    func openMobileBackupStorageUnavailable(input: MobileBackupStorageUnavailableInput)
}
