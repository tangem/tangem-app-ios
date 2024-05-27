//
//  DecimalNumberFormatter.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import XCTest
@testable import Tangem

class DecimalNumberFormatterTests: XCTestCase {
    func testFormatterWithRussianLocale() {
        let numberFormatter = NumberFormatter()
        numberFormatter.locale = Locale(identifier: "ru_RU")
        numberFormatter.numberStyle = .decimal

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
        numberFormatter.numberStyle = .decimal

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

    func testCurrencyFormatterWithUSALocale() {
        let numberFormatter = NumberFormatter()
        numberFormatter.locale = Locale(identifier: "en_US")
        numberFormatter.numberStyle = .currency
        numberFormatter.currencySymbol = "NEAR"

        let formatter = DecimalNumberFormatter(numberFormatter: numberFormatter, maximumFractionDigits: 30)

        let unbreakableSpace = "\u{00a0}"

        let data: [(input: Decimal, expected: String)] = [
            (input: Decimal(string: "0.000")!, expected: "NEAR\(unbreakableSpace)0"),
            (input: Decimal(string: "0.0001")!, expected: "NEAR\(unbreakableSpace)0.0001"),
            (input: Decimal(string: "15320")!, expected: "NEAR\(unbreakableSpace)15,320"),
            (input: Decimal(string: "1234.56")!, expected: "NEAR\(unbreakableSpace)1,234.56"),
            (input: Decimal(string: "0.123456789")!, expected: "NEAR\(unbreakableSpace)0.123456789"),
            (input: Decimal(string: "1.111222333444555666777888999")!, expected: "NEAR\(unbreakableSpace)1.111222333444555666777888999"),
            (input: Decimal(string: "13579.111222333444555666777888999")!, expected: "NEAR\(unbreakableSpace)13,579.111222333444555666777888999"),
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
            numberFormatter.numberStyle = .decimal
            let formatter = DecimalNumberFormatter(
                numberFormatter: numberFormatter,
                maximumFractionDigits: testCase.digits
            )

            let decimalToString = formatter.format(value: testCase.decimal)
            XCTAssertEqual(decimalToString, testCase.string)

            let stringToString = formatter.format(value: testCase.string)
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
