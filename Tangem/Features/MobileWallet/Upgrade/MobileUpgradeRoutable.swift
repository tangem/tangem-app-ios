//
//  MobileUpgradeRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol MobileUpgradeRoutable: AnyObject {
    func openOnboarding(input: OnboardingInput)
    func openMail(dataCollector: EmailDataCollector, recipient: String)
    func closeMobileUpgrade()
}
