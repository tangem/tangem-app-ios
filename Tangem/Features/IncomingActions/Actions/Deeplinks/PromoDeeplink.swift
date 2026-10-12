//
//  PromoDeeplink.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

private typealias Shared = IncomingActionConstants.DeeplinkParams

/// `tangem://promo?promo_code[&ref&campaign]`
struct PromoDeeplink: HostNamedDeeplink, Equatable {
    static let host = "promo"

    let code: String
    let refcode: String?
    let campaign: String?

    var action: DeeplinkNavigationAction { .promo(self) }
}

// MARK: - Parsing

extension PromoDeeplink {
    private enum Keys {
        static let refcode = "ref"
        static let campaign = "campaign"
    }

    init(link: DeeplinkURL) throws {
        let query = link.query

        // A token named next to a promo code means nothing here, but a malformed one still turns the link
        // away.
        try query.validate(Shared.tokenId, Shared.networkId)

        code = try query.required(Shared.promoCode)
        // Referral parameters are read the way AppsFlyer's are, so a link written by hand cannot store what
        // a OneLink never could: an unset parameter spelled out as `null` would pass as a real referral.
        refcode = ReferralParam.normalized(query.unchecked(Keys.refcode))
        campaign = ReferralParam.normalized(query.unchecked(Keys.campaign))
    }
}
