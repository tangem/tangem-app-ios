//
//  HotBackupNeededRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol HotBackupNeededRoutable: AnyObject {
    func dismissHotBackupNeeded()
    func openHotOnboarding(input: HotOnboardingInput)
}
