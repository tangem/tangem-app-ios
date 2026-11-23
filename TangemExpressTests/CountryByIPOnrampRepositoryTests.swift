//
//  CountryByIPOnrampRepositoryTests.swift
//  TangemExpressTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemExpress

@Suite("Onramp repository with the country detected by IP")
struct CountryByIPOnrampRepositoryTests {
    @Test("Without a currency picked by the user the country's default currency is used")
    func countryDefaultCurrency() {
        let sut = makeSUT()

        sut.selectCountry(.spain)

        #expect(sut.preferenceCountry == .spain)
        #expect(sut.preferenceCurrency == .eur)
    }

    @Test("A currency picked by the user wins over the country's default and survives a country change")
    func userCurrencyWins() {
        let sut = makeSUT()

        sut.selectCurrency(.usd)
        sut.selectCountry(.spain)

        #expect(sut.preferenceCurrency == .usd)
    }

    @Test("Only the user's currency is persisted, the country is not")
    func onlyUserCurrencyIsPersisted() {
        let storage = OnrampStorageStub()
        let sut = makeSUT(storage: storage)

        sut.selectCountry(.spain)
        sut.selectCurrency(.usd)

        let reopened = makeSUT(storage: storage)
        #expect(reopened.preferenceCountry == nil)
        #expect(reopened.preferenceCurrency == .usd)
    }

    @Test("Selecting a country keeps the currency the user picked")
    func selectCountryKeepsUserCurrency() {
        let storage = OnrampStorageStub()
        let sut = makeSUT(storage: storage)
        sut.selectCurrency(.usd)

        sut.selectCountry(.spain)

        #expect(sut.preferenceCountry == .spain)
        #expect(sut.preferenceCurrency == .usd)
        #expect(makeSUT(storage: storage).preferenceCurrency == .usd)
    }

    @Test("Selecting a country without a user's currency doesn't persist the country's default")
    func selectCountryDoesNotPersistDefaultCurrency() {
        let storage = OnrampStorageStub()
        let sut = makeSUT(storage: storage)

        sut.selectCountry(.spain)

        #expect(sut.preferenceCurrency == .eur)
        #expect(makeSUT(storage: storage).preferenceCurrency == nil)
    }

    @Test("A session currency wins over the user's currency and is not persisted")
    func sessionCurrencyIsNotPersisted() {
        let storage = OnrampStorageStub()
        let sut = makeSUT(storage: storage)
        sut.selectCurrency(.eur)

        sut.updatePreference(currency: .usd)

        #expect(sut.preferenceCurrency == .usd)
        #expect(makeSUT(storage: storage).preferenceCurrency == .eur)
    }

    @Test("A currency the user picks replaces the session currency")
    func userCurrencyReplacesSessionCurrency() {
        let sut = makeSUT()
        sut.updatePreference(currency: .usd)

        sut.selectCurrency(.eur)

        #expect(sut.preferenceCurrency == .eur)
    }

    @Test("Two repositories on one store see the user's currency at once")
    func sharedStorePropagatesUserCurrency() {
        let store = OnrampUserCurrencyStore(storage: OnrampStorageStub())
        let flow = CountryByIPOnrampRepository(userCurrencyStore: store)
        let banner = CountryByIPOnrampRepository(userCurrencyStore: store)

        flow.selectCurrency(.eur)

        #expect(banner.preferenceCurrency == .eur)
    }

    @Test("The publisher emits the country with the resolved currency")
    func publisherResolvesCurrency() {
        let sut = makeSUT()
        var emitted: [OnrampPreference] = []
        let cancellable = sut.preferencePublisher.sink { emitted.append($0) }

        sut.selectCountry(.spain)
        cancellable.cancel()

        #expect(emitted == [
            OnrampPreference(country: nil, currency: nil),
            OnrampPreference(country: .spain, currency: .eur),
        ])
    }
}

// MARK: - Helpers

private extension CountryByIPOnrampRepositoryTests {
    func makeSUT(storage: OnrampStorage = OnrampStorageStub()) -> OnrampRepository {
        CountryByIPOnrampRepository(userCurrencyStore: OnrampUserCurrencyStore(storage: storage))
    }
}

private extension OnrampFiatCurrency {
    static let eur = OnrampFiatCurrency(identity: .init(name: "Euro", code: "EUR", image: nil), precision: 2)
    static let usd = OnrampFiatCurrency(identity: .init(name: "US Dollar", code: "USD", image: nil), precision: 2)
}

private extension OnrampCountry {
    static let spain = OnrampCountry(identity: .init(name: "Spain", code: "ES", image: nil), currency: .eur, onrampAvailable: true)
}

// MARK: - Stubs

private final class OnrampStorageStub: OnrampStorage {
    private var stored: OnrampUserPreference?

    func save(preference: OnrampUserPreference) {
        stored = preference
    }

    func preference() -> OnrampUserPreference? {
        stored
    }
}
