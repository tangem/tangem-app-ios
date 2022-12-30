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
    private var formatter: GroupedNumberFormatter!

    override func setUp() {
        super.setUp()
        formatter = GroupedNumberFormatter(
            maximumFractionDigits: 8,
            numberFormatter: .grouped,
            decimalSeparator: ","
        )
    }

    func testFormatter() {
        let data = [
            (input: "0,000", result: "0,000"),
            (input: "0,0001", result: "0,0001"),
            (input: "15320", result: "15 320"),
            (input: "1234,56", result: "1 234,56"),
            (input: "0,123456789", result: "0,12345678"), // reduce maximumFractionDigits
        ]

        data.forEach { input, result in
            XCTAssertEqual(formatter.format(from: input), result)
        }
    }
}
