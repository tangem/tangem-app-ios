//
//  WelcomeOnboardingsHelper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct WelcomeOnboardingsHelper {
    func getStartupOnboarding() -> WelcomeStartupOnboarding? {
        // More specific than the generic Tangem Pay onboarding link, so it wins.
        if let campaignKey = TangemPayCampaignService().pendingCampaignKey {
            return .tangemPayCampaign(campaignKey: campaignKey)
        }

        let needsTangemPayOnboarding = TangemPayMobileOnboardingService().isOnboardingNeeded
        if needsTangemPayOnboarding {
            return .tangemPayMobile
        }

        return nil
    }
}

enum WelcomeStartupOnboarding {
    case tangemPayMobile
    case tangemPayCampaign(campaignKey: String)
}
