//
//  TangemPayMobileOnboardingService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct TangemPayMobileOnboardingService {
    private var isFeatureAvailable: Bool {
        FeatureProvider.isAvailable(.tangemPayMobileOnboarding)
    }

    var isOnboardingNeeded: Bool {
        guard isFeatureAvailable else { return false }
        return AppSettings.shared.needsTangemPayMobileOnboarding
    }

    func markOnboardingNeeded() {
        guard isFeatureAvailable else { return }
        AppSettings.shared.needsTangemPayMobileOnboarding = true
    }

    func markOnboardingShown() {
        AppSettings.shared.needsTangemPayMobileOnboarding = false
    }
}
