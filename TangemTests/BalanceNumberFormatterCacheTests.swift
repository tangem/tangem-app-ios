//
//  BalanceNumberFormatterCacheTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

/// The cache must return formatters equivalent to `BalanceFormatter`'s factory methods, else cached balances would diverge.
@Suite("BalanceNumberFormatterCache")
struct BalanceNumberFormatterCacheTests {
    private let balanceFormatter = BalanceFormatter()

    private static let values: [Decimal] = [
        0,
        Decimal(stringValue: "0.01")!,
        Decimal(stringValue: "12.3456789")!,
        Decimal(stringValue: "1234567.89")!,
    ]

    @Test("Cached fiat formatter matches a freshly built one", arguments: ["USD", "RUB", "EUR"])
    func fiatParity(currencyCode: String) {
        let options: BalanceFormattingOptions = .defaultFiatFormattingOptions
        let cached = BalanceNumberFormatterCache.fiatFormatter(forCurrencyCode: currencyCode, locale: .current, formattingOptions: options)
        let fresh = balanceFormatter.makeDefaultFiatFormatter(forCurrencyCode: currencyCode, formattingOptions: options)

        for value in Self.values {
            #expect(cached.string(from: value as NSDecimalNumber) == fresh.string(from: value as NSDecimalNumber))
        }
    }

    @Test("Cached crypto formatter matches a freshly built one", arguments: ["BTC", "ETH", "SOL"])
    func cryptoParity(currencyCode: String) {
        let options: BalanceFormattingOptions = .defaultCryptoFormattingOptions
        let cached = BalanceNumberFormatterCache.cryptoFormatter(forCurrencyCode: currencyCode, locale: .current, formattingOptions: options)
        let fresh = balanceFormatter.makeDefaultCryptoFormatter(forCurrencyCode: currencyCode, formattingOptions: options)

        for value in Self.values {
            #expect(cached.string(from: value as NSDecimalNumber) == fresh.string(from: value as NSDecimalNumber))
        }
    }

    @Test("Different currency codes produce different cached formatters")
    func differentCurrencyCodes() {
        let options: BalanceFormattingOptions = .defaultFiatFormattingOptions
        let usd = BalanceNumberFormatterCache.fiatFormatter(forCurrencyCode: "USD", locale: .current, formattingOptions: options)
        let eur = BalanceNumberFormatterCache.fiatFormatter(forCurrencyCode: "EUR", locale: .current, formattingOptions: options)

        #expect(usd !== eur)
    }
}
