//
//  MarketsTokenPriceFormatterTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

/// Tests for `MarketsTokenPriceFormatter` which dynamically adjusts the number of fractional digits
/// based on the magnitude of the price value. The scale formula for values < 1 is:
/// `(number of leading zeroes in fractional part) + fractionalPartLengthAfterLeadingZeroes`.
///
/// - Note: The formatter uses a shared static cache for computed scales. Tests are serialized
///   to avoid data races on this static state.
@Suite("MarketsTokenPriceFormatter", .serialized)
struct MarketsTokenPriceFormatterTests {
    private static let currencyCode = "USD"

    private let appSettingsGuard: AppSettingsGuard

    init() {
        appSettingsGuard = AppSettingsGuard(currencyCode: Self.currencyCode)
    }

    // MARK: - Nil value

    @Test("Nil value returns default empty balance string")
    func nilValue() {
        let sut = MarketsTokenPriceFormatter()

        #expect(sut.formatPrice(nil) == BalanceFormatter.defaultEmptyBalanceString)
    }

    // MARK: - Values >= 1 use default fiat formatting (scale 2)

    @Test(
        "Values >= 1 use default fiat formatting with scale 2",
        arguments: [
            Decimal(1),
            Decimal(stringValue: "1.5")!,
            Decimal(stringValue: "42.567")!,
            Decimal(stringValue: "1234.5")!,
            Decimal(1000000),
        ]
    )
    func valuesGreaterThanOrEqualToOne(value: Decimal) {
        let sut = MarketsTokenPriceFormatter()
        let expected = Self.expectedPrice(value, scale: 2)

        #expect(sut.formatPrice(value) == expected)
    }

    // MARK: - Dynamic scale for values < 1

    @Test("Scale adapts based on value magnitude", arguments: Self.dynamicScaleTestCases)
    func dynamicScaleForSmallValues(testCase: ScaleTestCase) {
        let sut = MarketsTokenPriceFormatter()
        let expected = Self.expectedPrice(testCase.value, scale: testCase.expectedScale)

        #expect(sut.formatPrice(testCase.value) == expected)
    }

    // MARK: - Negative values

    /// Negative values are **not supported** by `MarketsTokenPriceFormatter`.
    ///
    /// Any negative value passes the `value < 1.0` guard and enters the scale calculation loop.
    /// The `while threshold > value` condition is always `true` because `threshold` is always
    /// positive (or zero after underflow), and a positive number (or zero) is always greater than
    /// a negative number. This results in an infinite loop.
    ///
    /// This is acceptable because the formatter is designed exclusively for token prices,
    /// which are always non-negative.
    @Test(
        "Negative values are not supported",
        .disabled("Causes an infinite loop: positive threshold is always > negative value")
    )
    func negativeValues() {
        let sut = MarketsTokenPriceFormatter()
        _ = sut.formatPrice(Decimal(stringValue: "-0.5")!)
    }

    // MARK: - Boundary values

    @Test("Exactly 1.0 uses default fiat formatting, not dynamic scale")
    func exactlyOneUsesDefaultFormatting() {
        let sut = MarketsTokenPriceFormatter()
        let value = Decimal(1)

        // 1.0 is NOT < 1.0, so it takes the default formatting path (scale 2)
        #expect(sut.formatPrice(value) == Self.expectedPrice(value, scale: 2))
    }

    @Test("Value at exact threshold uses that threshold's scale")
    func valueAtExactThreshold() {
        let sut = MarketsTokenPriceFormatter()

        // 0.1 exactly equals the threshold for scale 4
        let value = Decimal(stringValue: "0.1")!
        #expect(sut.formatPrice(value) == Self.expectedPrice(value, scale: 4))

        // 0.01 exactly equals the threshold for scale 5
        let value2 = Decimal(stringValue: "0.01")!
        #expect(sut.formatPrice(value2) == Self.expectedPrice(value2, scale: 5))
    }

    @Test("Value just below threshold uses the next scale")
    func valueJustBelowThreshold() {
        let sut = MarketsTokenPriceFormatter()

        // 0.09999 is below 0.1 → falls into [0.01, 0.1) → scale 5
        let value = Decimal(stringValue: "0.09999")!
        #expect(sut.formatPrice(value) == Self.expectedPrice(value, scale: 5))

        // 0.00999 is below 0.01 → falls into [0.001, 0.01) → scale 6
        let value2 = Decimal(stringValue: "0.00999")!
        #expect(sut.formatPrice(value2) == Self.expectedPrice(value2, scale: 6))
    }

    // MARK: - Rounding behavior

    @Test("Values are rounded correctly at the scale boundary")
    func roundingAtScaleBoundary() {
        let sut = MarketsTokenPriceFormatter()

        // 0.12345 in [0.1, 1.0) → scale 4, rounding mode .plain
        // 0.12345 rounded to 4 decimal places → 0.1235 (5 rounds up)
        let value = Decimal(stringValue: "0.12345")!
        let expected = Self.expectedPrice(value, scale: 4)
        #expect(sut.formatPrice(value) == expected)

        // 0.123449 → scale 4, rounds to 0.1234 (4 rounds down)
        let value2 = Decimal(stringValue: "0.123449")!
        let expected2 = Self.expectedPrice(value2, scale: 4)
        #expect(sut.formatPrice(value2) == expected2)
    }

    @Test("Value that rounds up across the 1.0 boundary")
    func roundingAcrossOneBoundary() {
        let sut = MarketsTokenPriceFormatter()

        // 0.999999 in [0.1, 1.0) → scale 4
        // Rounds to 1.0000 at scale 4
        let value = Decimal(stringValue: "0.999999")!
        let expected = Self.expectedPrice(value, scale: 4)
        #expect(sut.formatPrice(value) == expected)
    }

    // MARK: - Consistency

    @Test("Multiple calls with the same value return identical results")
    func consistentResults() {
        let sut = MarketsTokenPriceFormatter()
        let value = Decimal(stringValue: "0.001234")!

        let result1 = sut.formatPrice(value)
        let result2 = sut.formatPrice(value)
        #expect(result1 == result2)
    }

    @Test("Different formatter instances return identical results for the same value")
    func differentInstancesReturnSameResults() {
        let value = Decimal(stringValue: "0.001234")!
        let sut1 = MarketsTokenPriceFormatter()
        let sut2 = MarketsTokenPriceFormatter()

        #expect(sut1.formatPrice(value) == sut2.formatPrice(value))
    }

    // MARK: - Test data

    private static var dynamicScaleTestCases: [ScaleTestCase] {
        [
            // [0.1, 1.0) → 0 leading zeroes + 4 = scale 4
            ScaleTestCase(value: Decimal(stringValue: "0.5")!, expectedScale: 4),
            ScaleTestCase(value: Decimal(stringValue: "0.1")!, expectedScale: 4),
            ScaleTestCase(value: Decimal(stringValue: "0.9999")!, expectedScale: 4),

            // [0.01, 0.1) → 1 leading zero + 4 = scale 5
            ScaleTestCase(value: Decimal(stringValue: "0.05")!, expectedScale: 5),
            ScaleTestCase(value: Decimal(stringValue: "0.01")!, expectedScale: 5),
            ScaleTestCase(value: Decimal(stringValue: "0.09999")!, expectedScale: 5),

            // [0.001, 0.01) → 2 leading zeroes + 4 = scale 6
            ScaleTestCase(value: Decimal(stringValue: "0.005")!, expectedScale: 6),
            ScaleTestCase(value: Decimal(stringValue: "0.001")!, expectedScale: 6),
            ScaleTestCase(value: Decimal(stringValue: "0.001234")!, expectedScale: 6),

            // [0.0001, 0.001) → 3 leading zeroes + 4 = scale 7
            ScaleTestCase(value: Decimal(stringValue: "0.0005")!, expectedScale: 7),
            ScaleTestCase(value: Decimal(stringValue: "0.0001")!, expectedScale: 7),

            // [10^-8, 10^-7) → 7 leading zeroes + 4 = scale 11
            ScaleTestCase(value: Decimal(stringValue: "0.00000005")!, expectedScale: 11),
            ScaleTestCase(value: Decimal(stringValue: "0.00000001")!, expectedScale: 11),

            // [10^-12, 10^-11) → 11 leading zeroes + 4 = scale 15
            ScaleTestCase(value: Decimal(stringValue: "0.0000000000005")!, expectedScale: 15),

            // [10^-18, 10^-17) → 17 leading zeroes + 4 = scale 21 (smallest ETH wei-scale value)
            ScaleTestCase(value: Decimal(sign: .plus, exponent: -18, significand: 5), expectedScale: 21),

            // [10^-30, 10^-29) → 29 leading zeroes + 4 = scale 33
            ScaleTestCase(value: Decimal(sign: .plus, exponent: -30, significand: 5), expectedScale: 33),
        ]
    }

    // MARK: - Helpers

    /// Builds the expected formatted string using the same `BalanceFormatter` chain
    /// that `MarketsTokenPriceFormatter` delegates to. This makes assertions locale-independent.
    private static func expectedPrice(_ value: Decimal?, scale: Int) -> String {
        let balanceFormatter = BalanceFormatter()
        var options: BalanceFormattingOptions = .defaultFiatFormattingOptions
        options.maxFractionDigits = scale
        options.roundingType = .default(roundingMode: .plain, scale: scale)

        return balanceFormatter.formatFiatBalance(
            value,
            currencyCode: currencyCode,
            formattingOptions: options
        )
    }
}

// MARK: - Auxiliary types

extension MarketsTokenPriceFormatterTests {
    struct ScaleTestCase: Sendable, CustomTestStringConvertible {
        let value: Decimal
        let expectedScale: Int

        var testDescription: String {
            "\(value) → scale \(expectedScale)"
        }
    }

    /// RAII pattern based guard that saves `AppSettings.shared.selectedCurrencyCode` on `init`
    /// and restores the original value on `deinit`.
    /// Required since Swift Testing uses structs and obviously structs have no `deinit`.
    final class AppSettingsGuard {
        private let originalCurrencyCode: String

        init(currencyCode: String) {
            originalCurrencyCode = AppSettings.shared.selectedCurrencyCode
            AppSettings.shared.selectedCurrencyCode = currencyCode
        }

        deinit {
            AppSettings.shared.selectedCurrencyCode = originalCurrencyCode
        }
    }
}
