//
//  AppsFlyerDeepLinkParams.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct AppsFlyerDeepLinkParams {
    let value: String?
    let refcode: String?
    let campaign: String?

    var isReferralDeepLink: Bool {
        value == AppsFlyerDeepLinkResolver.AppsflyerDeepLinkType.referral
    }

    init(clickEvent: [AnyHashable: Any]) {
        value = clickEvent.appsFlyerStringValue(forKey: AppsFlyerDeepLinkKeys.value)
        refcode = ReferralParam.normalized(clickEvent.appsFlyerStringValue(forKey: AppsFlyerDeepLinkKeys.sub1))
        campaign = ReferralParam.normalized(clickEvent.appsFlyerStringValue(forKey: AppsFlyerDeepLinkKeys.sub2))
    }
}

private extension [AnyHashable: Any] {
    func appsFlyerStringValue(forKey key: String) -> String? {
        self[key] as? String
    }
}
