//
//  OnrampStorage.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public protocol OnrampStorage {
    func save(preference: OnrampUserPreference)
    func preference() -> OnrampUserPreference?
}

public struct OnrampUserPreference: Codable {
    var country: Country?
    var currency: Currency?

    init(country: Country? = nil, currency: Currency? = nil) {
        self.country = country
        self.currency = currency
    }
}

extension OnrampUserPreference {
    struct Country: Codable {
        let name: String
        let code: String
        let image: URL?
        let currency: Currency
        let onrampAvailable: Bool
    }

    struct Currency: Codable {
        let name: String
        let code: String
        let image: URL?
        let precision: Int
    }
}

extension OnrampUserPreference.Currency {
    init(_ currency: OnrampFiatCurrency) {
        self.init(
            name: currency.identity.name,
            code: currency.identity.code,
            image: currency.identity.image,
            precision: currency.precision
        )
    }

    var fiatCurrency: OnrampFiatCurrency {
        OnrampFiatCurrency(identity: .init(name: name, code: code, image: image), precision: precision)
    }
}
