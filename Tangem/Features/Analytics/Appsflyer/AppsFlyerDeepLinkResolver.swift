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
        guard let deepLinkValue = deepLink.getValue(forKey: AppsFlyerDeepLinkKeys.value) else {
            AppsflyerLogger.info("Could not extract deep_link_value")
            return
        }

        switch deepLinkValue {
        case AppsflyerDeepLinkType.referral:
            return AppsFlyerDeepReferralHandler().handle(deepLink)
        default:
            return
        }
    }
}

extension AppsFlyerDeepLinkResolver {
    enum AppsflyerDeepLinkType {
        static let referral = "referral"
    }
}

// MARK: DeepLink+

extension DeepLink {
    func getValue(forKey: String) -> String? {
        guard clickEvent.keys.contains(forKey) else {
            return nil
        }

        return clickEvent[forKey] as? String
    }
}
