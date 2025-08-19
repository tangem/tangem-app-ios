//
//  MobileBackupNeededRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol MobileBackupNeededRoutable: AnyObject {
    func dismissMobileBackupNeeded()
    func openMobileOnboarding(input: MobileOnboardingInput)
}
