//
//  UITestOnrampRepository.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

public class UITestOnrampRepository: OnrampRepository {
    private let preference = CurrentValueSubject<OnrampPreference, Never>(
        OnrampPreference(
            country: UITestOnrampRepository.defaultCountry,
            currency: UITestOnrampRepository.defaultCurrency
        )
    )

    public init() {}

    public var preferenceCountry: OnrampCountry? {
        preference.value.country
    }

    public var preferenceCurrency: OnrampFiatCurrency? {
        preference.value.currency
    }

    public var preferencePublisher: AnyPublisher<OnrampPreference, Never> {
        preference.eraseToAnyPublisher()
    }

    public func updatePreference(country: OnrampCountry?, currency: OnrampFiatCurrency?) {
        var currentPreference = preference.value

        if let country = country {
            currentPreference = OnrampPreference(
                country: country,
                currency: currentPreference.currency
            )
        }

        if let currency = currency {
            currentPreference = OnrampPreference(
                country: currentPreference.country,
                currency: currency
            )
        }

        preference.send(currentPreference)
    }
}

// MARK: - Default values

private extension UITestOnrampRepository {
    static var defaultCountry: OnrampCountry {
        let defaultCountryIdentity = OnrampIdentity(
            name: "Spain",
            code: "ES",
            image: URL(string: "https://s3.eu-central-1.amazonaws.com/tangem.api/express/Countries/Name%3DES%20Spain.png")
        )
        let defaultCountry = OnrampCountry(
            identity: defaultCountryIdentity,
            currency: defaultCurrency,
            onrampAvailable: true
        )
        return defaultCountry
    }

    static var defaultCurrency: OnrampFiatCurrency {
        let defaultCurrencyIdentity = OnrampIdentity(
            name: "Euro",
            code: "EUR",
            image: URL(string: "https://s3.eu-central-1.amazonaws.com/tangem.api/express/Currencies/EUR.png")
        )
        let defaultCurrency = OnrampFiatCurrency(identity: defaultCurrencyIdentity, precision: 2)
        return defaultCurrency
    }
}
