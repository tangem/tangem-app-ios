//
//  AppsFlyerDeepLinkResolver.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//
import AppsFlyerLib

struct AppsFlyerDeepLinkResolver {
    func resolveDeeplink(_ deepLink: DeepLink) {
        resolve(clickEvent: deepLink.clickEvent)
    }

    func resolve(clickEvent: [AnyHashable: Any]) {
        let params = AppsFlyerDeepLinkParams(clickEvent: clickEvent)

        // A scenario link may carry a referral code as well, so the params are stored for any deep_link_value.
        // Navigation below, and the promo gate inside the handler, stay bound to the known deep link values.
        AppsFlyerDeepReferralHandler().handle(params)

        switch params.value {
        case AppsflyerDeepLinkType.referral:
            break
        case AppsflyerDeepLinkType.tangemPayMobileOnboarding:
            TangemPayMobileOnboardingService().markOnboardingNeeded()
        default:
            guard let deepLinkValue = params.value,
                  let campaignKey = TangemPayCampaignService.campaignKey(fromDeepLinkValue: deepLinkValue) else {
                AppsflyerLogger.info("No navigation for deep_link_value: \(params.value ?? "nil")")
                return
            }

            TangemPayCampaignService().markPending(campaignKey: campaignKey)
        }
    }
}

extension AppsFlyerDeepLinkResolver {
    enum AppsflyerDeepLinkType {
        static let referral = "referral"
        static let tangemPayMobileOnboarding = "tpay_mobileonboard"
    }
}
