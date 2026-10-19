//
//  PromoDeeplink.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

private typealias Shared = IncomingActionConstants.DeeplinkParams

/// `tangem://promo?promo_code[&payment_network&payment_currency][&ref&campaign]`
struct PromoDeeplink: HostNamedDeeplink, Equatable {
    static let host = "promo"

    let code: String
    let token: PromotionToken
    let refcode: String?
    let campaign: String?

    var action: DeeplinkNavigationAction { .promo(self) }
}

// MARK: - Parsing

extension PromoDeeplink {
    private enum Keys {
        static let refcode = "ref"
        static let campaign = "campaign"
        static let paymentNetwork = "payment_network"
        static let paymentCurrency = "payment_currency"
    }

    init(link: DeeplinkURL) throws {
        let query = link.query

        // A token named next to a promo code means nothing here, but a malformed one still turns the link
        // away.
        try query.validate(Shared.tokenId, Shared.networkId)

        code = try query.required(Shared.promoCode)
        token = try Self.token(from: query)
        // Referral parameters are read the way AppsFlyer's are, so a link written by hand cannot store what
        // a OneLink never could: an unset parameter spelled out as `null` would pass as a real referral.
        refcode = ReferralParam.normalized(query.unchecked(Keys.refcode))
        campaign = ReferralParam.normalized(query.unchecked(Keys.campaign))
    }

    private static func token(from query: DeeplinkQuery) throws -> PromotionToken {
        let networkId = try query.optional(Keys.paymentNetwork, lowercased: true)
        let currencySymbol = try query.optional(Keys.paymentCurrency)

        switch (networkId, currencySymbol) {
        case (.some(let networkId), .some(let currencySymbol)):
            return .deeplink(networkId: networkId, currencySymbol: currencySymbol)
        case (.none, .none):
            return .bitcoin
        case (.none, .some):
            throw DeeplinkQuery.ValidationError.missingValue(key: Keys.paymentNetwork)
        case (.some, .none):
            throw DeeplinkQuery.ValidationError.missingValue(key: Keys.paymentCurrency)
        }
    }
}
