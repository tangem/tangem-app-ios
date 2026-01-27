//
//  MobileOnboardingInput.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct MobileOnboardingInput {
    let flow: MobileOnboardingFlow
    let shouldLogOnboardingStartedAnalytics: Bool

    init(flow: MobileOnboardingFlow, shouldLogOnboardingStartedAnalytics: Bool = true) {
        self.flow = flow
        self.shouldLogOnboardingStartedAnalytics = shouldLogOnboardingStartedAnalytics
    }
}
