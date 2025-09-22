//
//  PredefinedOnrampParametersBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemExpress
import TangemFoundation

struct PredefinedOnrampParametersBuilder {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    private let userWalletId: UserWalletId
    private let onrampPreference: OnrampPreference?

    private let expressAPIProvider: any ExpressAPIProvider

    init(userWalletId: UserWalletId, onrampPreference: OnrampPreference?) {
        self.userWalletId = userWalletId
        self.onrampPreference = onrampPreference

        expressAPIProvider = ExpressAPIProviderFactory()
            .makeExpressAPIProvider(userWalletId: userWalletId, refcode: .none)
    }

    func prepare() async -> PredefinedOnrampParameters? {
        guard moreThanOneDayAfterFirstWalletUse() else {
            return nil
        }

        guard let parameters = await getParameters() else {
            return nil
        }

        return parameters
    }

    private func moreThanOneDayAfterFirstWalletUse() -> Bool {
        guard let startWalletUsageDate = AppSettings.shared.startWalletUsageDate else {
            return false
        }

        guard let oneDayLater = Calendar.current.date(byAdding: .day, value: 1, to: startWalletUsageDate) else {
            return false
        }

        return oneDayLater < Date.now
    }

    private func getParameters() async -> PredefinedOnrampParameters? {
        var currency: OnrampFiatCurrency? = onrampPreference?.currency
        var country: OnrampCountry? = onrampPreference?.country

        let haveToDefine = currency == nil || country == nil
        if haveToDefine {
            let definied = try? await expressAPIProvider.onrampCountryByIP()
            if currency == nil {
                currency = definied?.currency
            }

            if country == nil {
                country = definied
            }
        }

        guard let country, let currency else {
            return nil
        }

        // Check the banner is available in user's country
        guard PredefinedOnrampParametersBuilder.countries.contains(where: { $0.caseInsensitiveEquals(to: country.identity.name) }) else {
            return nil
        }

        // Check the banner is available in user's currency
        guard let fiat = PredefinedOnrampParametersBuilder.fiatPairs[currency.identity.code] else {
            return nil
        }

        let preferredValues = PreferredValues(paymentMethodType: .sepa)
        return PredefinedOnrampParameters(amount: fiat, preferredValues: preferredValues)
    }
}

private extension PredefinedOnrampParametersBuilder {
    static let fiatPairs: [String: Decimal] = [
        "ALL": 10000,
        "EUR": 100,
        "BGN": 200,
        "CZK": 2500,
        "DKK": 800,
        "HUF": 40000,
        "ISK": 14000,
        "CHF": 100,
        "MDL": 2000,
        "MKD": 6000,
        "NOK": 1000,
        "PLN": 400,
        "RSD": 12000,
        "SEK": 1000,
        "GBP": 100,
    ]

    static let countries: [String] = [
        "Albania",
        "Andorra",
        "Austria",
        "Belgium",
        "Bulgaria",
        "Croatia",
        "Cyprus",
        "Czech Republic",
        "Denmark",
        "Estonia",
        "Finland",
        "France",
        "Germany",
        "Greece",
        "Hungary",
        "Iceland",
        "Ireland",
        "Italy",
        "Latvia",
        "Liechtenstein",
        "Lithuania",
        "Luxembourg",
        "Malta",
        "Moldova",
        "Monaco",
        "Montenegro",
        "Netherlands",
        "North Macedonia",
        "Norway",
        "Poland",
        "Portugal",
        "Romania",
        "San Marino",
        "Serbia",
        "Slovakia",
        "Slovenia",
        "Spain",
        "Sweden",
        "Switzerland",
        "United Kingdom",
        "Vatican City",
    ]
}
