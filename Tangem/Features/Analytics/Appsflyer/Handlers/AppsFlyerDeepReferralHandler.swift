//
//  AppsFlyerDeepReferralHandler.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct AppsFlyerDeepReferralHandler {
    @Injected(\.referralService) private var referralService: ReferralService
    @Injected(\.mobileWalletPromoService) private var mobileWalletPromoService: MobileWalletPromoService

    func handle(_ params: AppsFlyerDeepLinkParams) {
        guard let refcode = params.refcode else {
            AppsflyerLogger.info("Could not extract refcode")
            return
        }

        guard referralService.hasNoReferral else {
            AppsflyerLogger.info("Already has referral. Ignoring")
            return
        }

        // The mobile wallet promo replaces the intro stories and belongs to the referral scenario only,
        // while the refcode itself is stored for any deep link that carries it.
        if params.isReferralDeepLink {
            mobileWalletPromoService.setNeedsPromo()
        }

        referralService.saveAndBindIfNeeded(refcode: refcode, campaign: params.campaign)
        AppsflyerLogger.info("Referral was handled successfully. Refcode: \(refcode), campaign: \(String(describing: params.campaign))")
    }
}
