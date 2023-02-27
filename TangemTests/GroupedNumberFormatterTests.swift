//
//  GroupedNumberFormatter.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import XCTest
@testable import Tangem

class GroupedNumberFormatterTests: XCTestCase {
    func testFormatterWithRussianLocale() {
        let numberFormatter = NumberFormatter()
        numberFormatter.locale = Locale(identifier: "ru_RU")

        let formatter = GroupedNumberFormatter(numberFormatter: numberFormatter, maximumFractionDigits: 8)

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
            let result = formatter.format(from: input)
            XCTAssertEqual(result, expected)
        }
    }

    func testFormatterWithUSALocale() {
        let numberFormatter = NumberFormatter()
        numberFormatter.locale = Locale(identifier: "en_US")

        let formatter = GroupedNumberFormatter(numberFormatter: numberFormatter, maximumFractionDigits: 8)

        let data = [
            (input: "0.000", expected: "0.000"),
            (input: "0.0001", expected: "0.0001"),
            (input: "15320", expected: "15,320"),
            (input: "1234.56", expected: "1,234.56"),
            (input: "0.123456789", expected: "0.12345678"), // reduce maximumFractionDigits
        ]

        data.forEach { input, expected in
            let result = formatter.format(from: input)
            XCTAssertEqual(result, expected)
        }
    }
}
