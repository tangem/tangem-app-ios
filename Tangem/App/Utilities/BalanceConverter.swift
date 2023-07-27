//
//  BalanceConverter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct BalanceConverter {
    @Injected(\.ratesRepository) private var ratesRepository: RatesRepository

    /// Converts from crypto to fiat using `RatesProvider`. If values doesn't loaded will wait for loading info from backend and return converted value
    /// Will throw error if failed to load rates or failed to find currency with specified code
    /// - Parameters:
    ///   - value: Amout of crypto to convert to fiat
    ///   - cryptoCurrencyCode: Code for crypto currency
    ///   - fiatCurrencyCode: Code for fiat currency. Ignored for now
    /// - Returns: Converted decimal value in specified fiat currency
    func convertToFiat(value: Decimal, from cryptoCurrencyCode: String, to fiatCurrencyCode: String) async throws -> Decimal {
        let rate = try await ratesRepository.rate(for: cryptoCurrencyCode)
        let fiatValue = value * rate
        return fiatValue
    }
}
