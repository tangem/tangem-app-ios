//
//  CountryByIPOnrampRepository.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

final class CountryByIPOnrampRepository {
    private let userCurrencyStore: OnrampUserCurrencyStore
    private let session = CurrentValueSubject<Session, Never>(Session())

    init(userCurrencyStore: OnrampUserCurrencyStore) {
        self.userCurrencyStore = userCurrencyStore
    }
}

// MARK: - OnrampRepository

extension CountryByIPOnrampRepository: OnrampRepository {
    var preferenceCountry: OnrampCountry? {
        session.value.country
    }

    var preferenceCurrency: OnrampFiatCurrency? {
        session.value.currency ?? userCurrencyStore.currency ?? session.value.country?.currency
    }

    var preferencePublisher: AnyPublisher<OnrampPreference, Never> {
        Publishers.CombineLatest(session, userCurrencyStore.currencyPublisher)
            .map { session, userCurrency in
                OnrampPreference(country: session.country, currency: session.currency ?? userCurrency ?? session.country?.currency)
            }
            .eraseToAnyPublisher()
    }

    func updatePreference(country: OnrampCountry?, currency: OnrampFiatCurrency?) {
        var updated = session.value
        updated.country = country ?? updated.country
        updated.currency = currency ?? updated.currency
        session.send(updated)
    }

    func selectCountry(_ country: OnrampCountry) {
        updatePreference(country: country, currency: nil)
    }

    func selectCurrency(_ currency: OnrampFiatCurrency) {
        userCurrencyStore.save(currency)

        var updated = session.value
        updated.currency = nil
        session.send(updated)
    }
}

// MARK: - Session

private extension CountryByIPOnrampRepository {
    struct Session {
        var country: OnrampCountry?
        var currency: OnrampFiatCurrency?
    }
}
