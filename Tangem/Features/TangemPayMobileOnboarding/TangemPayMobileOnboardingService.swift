//
//  TangemPayMobileOnboardingService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct TangemPayMobileOnboardingService {
    var isOnboardingNeeded: Bool {
        AppSettings.shared.needsTangemPayMobileOnboarding
    }

    func markOnboardingNeeded() {
        AppSettings.shared.needsTangemPayMobileOnboarding = true
    }

    func markOnboardingShown() {
        AppSettings.shared.needsTangemPayMobileOnboarding = false
    }
}
