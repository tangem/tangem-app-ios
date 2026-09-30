//
//  TangemPayFiatAmountFormatterTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("TangemPayFiatAmountFormatter")
struct TangemPayFiatAmountFormatterTests {
    private let formatter = TangemPayFiatAmountFormatter(locale: Locale(identifier: "en_US"))

    // MARK: - Digits

    @Test(
        "always shows exactly two fraction digits",
        arguments: [
            ("12.3", "$12.30"),
            ("12", "$12.00"),
            ("0.5", "$0.50"),
            ("12345.675", "$12,345.68"),
            ("1234567.891", "$1,234,567.89"),
        ]
    )
    func alwaysShowsTwoFractionDigits(amount: String, expected: String) {
        #expect(formatter.format(decimal(amount), currencyCode: "USD") == expected)
    }

    @Test("digits and separators follow en_US whatever the device locale is")
    func digitsFollowEnUSRegardlessOfLocale() {
        let german = TangemPayFiatAmountFormatter(locale: Locale(identifier: "de_DE"))

        #expect(german.format(decimal("1234.5"), currencyCode: "USD") == "$1,234.50")
        #expect(german.format(decimal("1234.5"), currencyCode: "EUR") == "€1,234.50")
    }

    @Test("negative amounts keep the regular minus sign, zero has no sign")
    func negativeAndZero() {
        #expect(formatter.format(decimal("-12.3"), currencyCode: "USD") == "-$12.30")
        #expect(formatter.format(.zero, currencyCode: "USD") == "$0.00")
    }

    // MARK: - Whole amounts

    @Test("hidesFractionForWholeAmounts drops the fraction only when there is nothing to show")
    func hidesFractionForWholeAmounts() {
        #expect(formatter.format(decimal("5"), currencyCode: "USD", hidesFractionForWholeAmounts: true) == "$5")
        #expect(formatter.format(decimal("2.5"), currencyCode: "USD", hidesFractionForWholeAmounts: true) == "$2.50")
        #expect(formatter.format(decimal("5"), currencyCode: "USD") == "$5.00")
    }

    // MARK: - Currency symbol

    @Test("the currency code is case-insensitive")
    func currencyCodeIsCaseInsensitive() {
        #expect(formatter.format(decimal("1"), currencyCode: "eur") == "€1.00")
        #expect(formatter.format(decimal("1"), currencyCode: "usd") == "$1.00")
    }

    @Test("a locale without a region falls back to the en_US symbol instead of the dollar sign")
    func regionlessLocaleFallsBackToBaseSymbol() {
        let regionless = TangemPayFiatAmountFormatter(locale: Locale(identifier: "en"))

        #expect(regionless.format(decimal("12.3"), currencyCode: "EUR") == "€12.30")
    }

    @Test("an unknown currency falls back to its code")
    func unknownCurrencyFallsBackToCode() {
        let formatted = formatter.format(decimal("1"), currencyCode: "XYZ")

        #expect(formatted.hasPrefix("XYZ"))
        #expect(formatted.hasSuffix("1.00"))
    }

    // MARK: - Signed

    @Test(
        "formatSigned adds a plus to positive amounts only",
        arguments: [
            ("12.3", "+$12.30"),
            ("-12.3", "-$12.30"),
            ("0", "$0.00"),
        ]
    )
    func formatSignedAddsPlusToPositiveOnly(amount: String, expected: String) {
        #expect(formatter.formatSigned(decimal(amount), currencyCode: "USD") == expected)
    }

    // MARK: - Helpers

    private func decimal(_ string: String) -> Decimal {
        Decimal(string: string, locale: Locale(identifier: "en_US_POSIX")) ?? .zero
    }
}
