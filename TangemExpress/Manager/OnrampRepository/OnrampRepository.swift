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

    var preferenceCountryPublisher: AnyPublisher<OnrampCountry?, Never> { get }
    var preferenceCurrencyPublisher: AnyPublisher<OnrampFiatCurrency?, Never> { get }

    func updatePreference(country: OnrampCountry?, currency: OnrampFiatCurrency?)
}

public extension OnrampRepository {
    func updatePreference(country: OnrampCountry? = nil, currency: OnrampFiatCurrency? = nil) {
        updatePreference(country: country, currency: currency)
    }
}
