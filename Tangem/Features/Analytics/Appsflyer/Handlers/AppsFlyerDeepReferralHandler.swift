//
//  AppsFlyerDeepReferralHandler.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//
import AppsFlyerLib

struct AppsFlyerDeepReferralHandler {
    @Injected(\.referralService) private var referralService: ReferralService

    func handle(_ deepLink: DeepLink) {
        guard let refcode = deepLink.getValue(forKey: AppsFlyerDeepLinkKeys.sub1) else {
            AppsflyerLogger.info("Could not extract refcode")
            return
        }

        let campaign = deepLink.getValue(forKey: AppsFlyerDeepLinkKeys.sub2)

        if referralService.hasNoReferral {
            referralService.saveReferralIfNeeded(refcode: refcode, campaign: campaign)
            AppsflyerLogger.info("Referral was handled successfully. Refcode: \(refcode), campaign: \(String(describing: campaign))")
        } else {
            AppsflyerLogger.info("Already has referral. Ignoring")
        }
    }
}
