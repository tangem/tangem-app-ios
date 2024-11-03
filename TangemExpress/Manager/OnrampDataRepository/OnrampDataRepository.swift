//
//  OnrampDataRepository.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine

public protocol OnrampDataRepository: Actor {
    func paymentMethods() async throws -> [OnrampPaymentMethod]
    func countries() async throws -> [OnrampCountry]
    func currencies() async throws -> [OnrampFiatCurrency]
}

public extension OnrampDataRepository {
    var popularFiats: [OnrampFiatCurrency] {
        [
            OnrampFiatCurrency(
                identity: OnrampIdentity(
                    name: "Pound Sterling",
                    code: "GBP",
                    image: URL(string: "https://s3.eu-central-1.amazonaws.com/tangem.api/express/Currencies/GBP.png")!
                ),
                precision: 2
            ),
            OnrampFiatCurrency(
                identity: OnrampIdentity(
                    name: "US Dollar",
                    code: "USD",
                    image: URL(string: "https://s3.eu-central-1.amazonaws.com/tangem.api/express/Currencies/USD.png")!
                ),
                precision: 2
            ),
            OnrampFiatCurrency(
                identity: OnrampIdentity(
                    name: "Canadian Dollar",
                    code: "CAD",
                    image: URL(string: "https://s3.eu-central-1.amazonaws.com/tangem.api/express/Currencies/CAD.png")!
                ),
                precision: 2
            ),
            OnrampFiatCurrency(
                identity: OnrampIdentity(
                    name: "Australian Dollar",
                    code: "AUD",
                    image: URL(string: "https://s3.eu-central-1.amazonaws.com/tangem.api/express/Currencies/AUD.png")!
                ),
                precision: 2
            ),
            OnrampFiatCurrency(
                identity: OnrampIdentity(
                    name: "Hong Kong Dollar",
                    code: "HKD",
                    image: URL(string: "https://s3.eu-central-1.amazonaws.com/tangem.api/express/Currencies/HKD.png")!
                ),
                precision: 2
            ),
            OnrampFiatCurrency(
                identity: OnrampIdentity(
                    name: "Euro",
                    code: "EUR",
                    image: URL(string: "https://s3.eu-central-1.amazonaws.com/tangem.api/express/Currencies/EUR.png")!
                ),
                precision: 2
            ),
        ]
    }
}

public extension OnrampDataRepository {
    nonisolated var countriesPublisher: AnyPublisher<[OnrampCountry], Error> {
        Future.async {
            try await self.countries()
        }
        .eraseToAnyPublisher()
    }

    nonisolated var currenciesPublisher: AnyPublisher<[OnrampFiatCurrency], Error> {
        Future.async {
            try await self.currencies()
        }
        .eraseToAnyPublisher()
    }

    nonisolated var popularFiatsPublisher: AnyPublisher<[OnrampFiatCurrency], Error> {
        Future.async {
            await self.popularFiats
        }
        .eraseToAnyPublisher()
    }
}
