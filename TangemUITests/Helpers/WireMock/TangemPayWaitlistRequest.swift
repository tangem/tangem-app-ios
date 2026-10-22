//
//  TangemPayWaitlistRequest.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct TangemPayWaitlistRequest: Equatable, CustomStringConvertible {
    let email: String
    let marketingConsent: Bool
    let countryCode: String
    let regionCode: String?
    let product: String
    let containsRegionCode: Bool

    init(email: String, marketingConsent: Bool, countryCode: String, regionCode: String?) {
        self.email = email
        self.marketingConsent = marketingConsent
        self.countryCode = countryCode
        self.regionCode = regionCode
        product = Constants.product
        containsRegionCode = regionCode != nil
    }

    init?(body: String) {
        guard
            let data = body.data(using: .utf8),
            let payload = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
            let email = payload[Constants.Key.email] as? String,
            let marketingConsent = payload[Constants.Key.marketingConsent] as? Bool,
            let countryCode = payload[Constants.Key.countryCode] as? String,
            let product = payload[Constants.Key.product] as? String
        else {
            return nil
        }

        self.email = email
        self.marketingConsent = marketingConsent
        self.countryCode = countryCode
        self.product = product
        regionCode = payload[Constants.Key.regionCode] as? String
        containsRegionCode = payload.keys.contains(Constants.Key.regionCode)
    }

    var description: String {
        "\(email), marketing consent: \(marketingConsent), \(countryCode), region: \(regionCode ?? "none"), \(product)"
    }
}

private extension TangemPayWaitlistRequest {
    enum Constants {
        static let product = "PAYMENT_ACCOUNT"

        enum Key {
            static let email = "email"
            static let marketingConsent = "marketing_consent"
            static let countryCode = "country_code"
            static let regionCode = "region_code"
            static let product = "product"
        }
    }
}
