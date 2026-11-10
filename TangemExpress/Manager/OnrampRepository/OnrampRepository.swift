//
//  OnrampRepository.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine

public protocol OnrampRepository {
    var preferenceCountry: OnrampCountry? { get }
    var preferenceCurrency: OnrampFiatCurrency? { get }
    var preferencePublisher: AnyPublisher<OnrampPreference, Never> { get }

    func updatePreference(country: OnrampCountry?, currency: OnrampFiatCurrency?)
    func selectCountry(_ country: OnrampCountry)
    func selectCurrency(_ currency: OnrampFiatCurrency)
}

public extension OnrampRepository {
    func selectCountry(_ country: OnrampCountry) {
        updatePreference(country: country, currency: country.currency)
    }

    func selectCurrency(_ currency: OnrampFiatCurrency) {
        updatePreference(currency: currency)
    }

    func updatePreference(country: OnrampCountry? = nil, currency: OnrampFiatCurrency? = nil) {
        updatePreference(country: country, currency: currency)
    }
}
