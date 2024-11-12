//
//  OnrampDataRepository.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public protocol OnrampDataRepository: Actor {
    func paymentMethods() async throws -> [OnrampPaymentMethod]
    func countries() async throws -> [OnrampCountry]
    func currencies() async throws -> [OnrampFiatCurrency]
}

public extension OnrampDataRepository {
    nonisolated var popularFiatCodes: Set<String> {
        [
            "GBP",
            "USD",
            "CAD",
            "AUD",
            "HKD",
            "EUR",
        ]
    }
}
