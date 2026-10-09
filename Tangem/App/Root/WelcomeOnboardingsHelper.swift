//
//  WelcomeOnboardingsHelper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct WelcomeOnboardingsHelper {
    @Injected(\.pushNotificationsInteractor) private var pushNotificationsInteractor: PushNotificationsInteractor

    func getStartupOnboarding() -> WelcomeStartupOnboarding? {
        // More specific than the generic Tangem Pay onboarding link, so it wins.
        if let campaignKey = TangemPayCampaignService().pendingCampaignKey {
            return .tangemPayCampaign(campaignKey: campaignKey)
        }

        let needsTangemPayOnboarding = TangemPayMobileOnboardingService().isOnboardingNeeded
        if needsTangemPayOnboarding {
            return .tangemPayMobile
        } else {
            let pushFactory = PushNotificationsHelpersFactory()
            let isPushNotificationsAvailable = pushFactory
                .makeAvailabilityProviderForWelcomeOnboarding(using: pushNotificationsInteractor)
                .isAvailable

            let stepsBuilder = WelcomeOnboardingStepsBuilder(isPushNotificationsAvailable: isPushNotificationsAvailable)
            let steps = stepsBuilder.buildSteps()

            if !steps.isEmpty {
                return .welcome(steps: steps)
            }
        }

        return nil
    }
}

enum WelcomeStartupOnboarding {
    case welcome(steps: [WelcomeOnboardingStep])
    case tangemPayMobile
    case tangemPayCampaign(campaignKey: String)
}
