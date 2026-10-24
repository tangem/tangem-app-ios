//
//  PromoCampaignValueFormatterTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("PromoCampaignValueFormatter", .tags(.campaigns))
struct PromoCampaignValueFormatterTests {
    private let formatter = PromoCampaignValueFormatter(locale: Locale(identifier: "en_US"))

    @Test("A percent value is taken as percentage points, not as a fraction")
    func percentIsPercentagePoints() {
        #expect(formatter.format(Decimal(string: "0.1")!, type: .percent, currency: nil, tokenSymbols: []) == "0.10%")
        #expect(formatter.format(Decimal(string: "0.5")!, type: .percent, currency: nil, tokenSymbols: []) == "0.50%")
    }

    @Test("A whole fiat amount drops the fraction, a fractional one keeps two digits")
    func fiatMoney() {
        #expect(formatter.format(500, type: .money, currency: "USD", tokenSymbols: []) == "$500")
        #expect(formatter.format(Decimal(string: "12.5")!, type: .money, currency: "USD", tokenSymbols: []) == "$12.50")
    }

    @Test("A fiat currency code is recognised regardless of its case")
    func fiatCurrencyCodeCase() {
        #expect(formatter.format(500, type: .money, currency: "usd", tokenSymbols: []) == "$500")
    }

    @Test("A currency outside ISO 4217 is formatted as a token amount")
    func cryptoMoney() {
        #expect(formatter.format(5, type: .money, currency: "USDT", tokenSymbols: []) == "USDT\u{00A0}5")
        #expect(formatter.format(Decimal(string: "0.002")!, type: .money, currency: "ETH", tokenSymbols: []) == "ETH\u{00A0}0.002")
    }

    @Test("A payout token whose symbol is also an ISO 4217 code is formatted as a token amount")
    func payoutTokenSymbolOverridesISOCode() {
        let value = Decimal(string: "10.12345")!

        #expect(formatter.format(value, type: .money, currency: "MNT", tokenSymbols: ["MNT"]) == "MNT\u{00A0}10.12345")
        #expect(formatter.format(value, type: .money, currency: "mnt", tokenSymbols: ["MNT"]) == "mnt\u{00A0}10.12345")
        #expect(formatter.format(value, type: .money, currency: "MNT", tokenSymbols: []) != "MNT\u{00A0}10.12345")
    }

    @Test("Money without a currency falls back to a plain number")
    func moneyWithoutCurrency() {
        #expect(formatter.format(1500, type: .money, currency: nil, tokenSymbols: []) == "1,500")
    }

    @Test("A table cell without a column type is money when it carries a currency, a number otherwise")
    func untypedValue() {
        #expect(formatter.format(5, type: nil, currency: "USDT", tokenSymbols: []) == "USDT\u{00A0}5")
        #expect(formatter.format(Decimal(string: "1234.5")!, type: nil, currency: nil, tokenSymbols: []) == "1,234.5")
    }

    @Test("Separators follow the device region")
    func separatorsFollowRegion() {
        let russian = PromoCampaignValueFormatter(locale: Locale(identifier: "ru_RU"))

        #expect(russian.format(Decimal(string: "0.1")!, type: .percent, currency: nil, tokenSymbols: []) == "0,10%")
        #expect(russian.format(Decimal(string: "0.002")!, type: .money, currency: "ETH", tokenSymbols: []).hasPrefix("0,002"))
    }
}
