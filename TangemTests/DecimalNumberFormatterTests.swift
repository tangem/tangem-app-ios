//
//  DecimalNumberFormatter.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
@testable import Tangem

class DecimalNumberFormatterTests: XCTestCase {
    func testParsingLocalizedDigitsPreservesDecimalPrecision() {
        let cases = [
            (locale: "ar_SA", input: "١٬٢٣٤٫٥٦", expected: "1234.56"),
            (locale: "fa_IR", input: "۱٬۲۳۴٫۵۶", expected: "1234.56"),
            (locale: "ar_SA", input: "٠٫٠٠٠٠٠٠٠٠٠٠٠٠٠٠٠٠٠١", expected: "0.000000000000000001"),
            (locale: "fa_IR", input: "۰٫۰۰۰۰۰۰۰۰۰۰۰۰۰۰۰۰۰۱", expected: "0.000000000000000001"),
        ]

        for testCase in cases {
            let formatter = DecimalNumberFormatter(maximumFractionDigits: 18, locale: Locale(identifier: testCase.locale))

            XCTAssertEqual(formatter.mapToDecimal(string: testCase.input), Decimal(string: testCase.expected), testCase.locale)
        }
    }

    func testLocalizedDecimalRoundTripPreservesValue() {
        for localeIdentifier in ["en_US", "ru_RU", "ar_SA", "fa_IR"] {
            let formatter = DecimalNumberFormatter(maximumFractionDigits: 18, locale: Locale(identifier: localeIdentifier))

            for input in ["0", "1", "1234.56", "0.000000000000000001", "1234.123456789012345678"] {
                let value = Decimal(string: input)!
                let formatted: String = formatter.format(value: value)
                let rounded: Decimal? = formatter.format(value: value)

                XCTAssertEqual(formatter.mapToDecimal(string: formatted), value, "\(localeIdentifier): \(input)")
                XCTAssertEqual(rounded, value, "\(localeIdentifier): \(input)")
            }
        }
    }

    func testFormatterWithRussianLocale() {
        let numberFormatter = NumberFormatter()
        numberFormatter.locale = Locale(identifier: "ru_RU")

        let formatter = DecimalNumberFormatter(numberFormatter: numberFormatter, maximumFractionDigits: 8)
        let unbreakableSpace = "\u{00a0}"

        let data = [
            (input: "0,000", expected: "0,000"),
            (input: "0,0001", expected: "0,0001"),
            (input: "15320", expected: "15\(unbreakableSpace)320"),
            (input: "1234,56", expected: "1\(unbreakableSpace)234,56"),
            (input: "0,123456789", expected: "0,12345678"), // reduce maximumFractionDigits
        ]

        XCTAssertEqual(numberFormatter.groupingSeparator, unbreakableSpace)

        data.forEach { input, expected in
            let result = formatter.format(value: input)
            XCTAssertEqual(result, expected)
        }
    }

    func testFormatterWithUSALocale() {
        let numberFormatter = NumberFormatter()
        numberFormatter.locale = Locale(identifier: "en_US")

        let formatter = DecimalNumberFormatter(numberFormatter: numberFormatter, maximumFractionDigits: 8)

        let data = [
            (input: "0.000", expected: "0.000"),
            (input: "0.0001", expected: "0.0001"),
            (input: "15320", expected: "15,320"),
            (input: "1234.56", expected: "1,234.56"),
            (input: "0.123456789", expected: "0.12345678"), // reduce maximumFractionDigits
        ]

        data.forEach { input, expected in
            let result = formatter.format(value: input)
            XCTAssertEqual(result, expected)
        }
    }

    func testDecimalToStringFormatter() {
        let cases: [TestCase] = [
            TestCase(
                groupingSeparator: " ",
                decimalSeparator: ",",
                digits: 18,
                decimal: "1000.123456789012345678",
                string: "1 000,123456789012345678"
            ),
            TestCase(
                groupingSeparator: ",",
                decimalSeparator: ".",
                digits: 18,
                decimal: "1000.123456789012345678",
                string: "1,000.123456789012345678"
            ),
            TestCase(
                groupingSeparator: " ",
                decimalSeparator: ".",
                digits: 18,
                decimal: "1000.123456789012345678",
                string: "1 000.123456789012345678"
            ),
            TestCase(
                groupingSeparator: ".",
                decimalSeparator: ",",
                digits: 18,
                decimal: "1000.123456789012345678",
                string: "1.000,123456789012345678"
            ),
            TestCase(
                groupingSeparator: " ",
                decimalSeparator: ",",
                digits: 8,
                decimal: "1000.123456789012345678",
                string: "1 000,12345678"
            ),
            TestCase(
                groupingSeparator: ",",
                decimalSeparator: ".",
                digits: 8,
                decimal: "1000.123456789012345678",
                string: "1,000.12345678"
            ),
            TestCase(
                groupingSeparator: " ",
                decimalSeparator: ".",
                digits: 8,
                decimal: "1000.123456789012345678",
                string: "1 000.12345678"
            ),
            TestCase(
                groupingSeparator: ".",
                decimalSeparator: ",",
                digits: 8,
                decimal: "1000.123456789012345678",
                string: "1.000,12345678"
            ),
            TestCase(
                groupingSeparator: ".",
                decimalSeparator: ",",
                digits: 0,
                decimal: "1000.123456789012345678",
                string: "1.000"
            ),
            TestCase(
                groupingSeparator: ".",
                decimalSeparator: ",",
                digits: 0,
                decimal: "1000.123456789012345678",
                string: "1.000"
            ),
        ]

        cases.forEach { testCase in
            let numberFormatter = NumberFormatter()
            numberFormatter.groupingSeparator = testCase.groupingSeparator
            numberFormatter.decimalSeparator = testCase.decimalSeparator
            let formatter = DecimalNumberFormatter(
                numberFormatter: numberFormatter,
                maximumFractionDigits: testCase.digits
            )

            let decimalToString: String = formatter.format(value: testCase.decimal)
            XCTAssertEqual(decimalToString, testCase.string)

            let stringToString: String = formatter.format(value: testCase.string)
            XCTAssertEqual(stringToString, testCase.string)
        }
    }
}

extension DecimalNumberFormatterTests {
    struct TestCase {
        let groupingSeparator: String
        let decimalSeparator: String
        let digits: Int
        let decimal: Decimal
        let string: String

        init(
            groupingSeparator: String,
            decimalSeparator: String,
            digits: Int,
            decimal: String,
            string: String
        ) {
            self.groupingSeparator = groupingSeparator
            self.decimalSeparator = decimalSeparator
            self.digits = digits
            // I don't know why but just set decimal value isn't work
            self.decimal = Decimal(string: decimal)!
            self.string = string
        }
    }
}
