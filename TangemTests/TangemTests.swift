//
//  TangemTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import XCTest
import TangemSdk
@testable import Tangem

class TangemTests: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testParseConfig() throws {
        XCTAssertNoThrow(try CommonKeysManager())
    }

    func testDemoCardIds() throws {
        let cardIdRegex = try! NSRegularExpression(pattern: "[A-Z]{2}\\d{14}")
        for demoCardId in DemoUtil().demoCardIds {
            let range = NSRange(location: 0, length: demoCardId.count)
            let match = cardIdRegex.firstMatch(in: demoCardId, options: [], range: range)
            XCTAssertTrue(match != nil, "Demo Card ID \(demoCardId) is invalid")
        }
    }

    func testSignificantFractionDigitRounder() throws {
        let roundingMode: NSDecimalNumber.RoundingMode = .down

        let pairs: [(Double, Double)] = [
            (0.00, 0.00),
            (0.00000001, 0.00000001),
            (0.00002345, 0.00002),
            (0.000029, 0.00002),
            (0.000000000000000001, 0.000000000000000001),
            (0.0000000000000000001, 0.00),
            (1.00002345, 1.00),
            (1.45002345, 1.45),
        ]

        let rounder = SignificantFractionDigitRounder(roundingMode: roundingMode)

        for (value, expectedValue) in pairs {
            let roundedValue = rounder.round(value: Decimal(floatLiteral: value))
            let roundedDoubleValue = NSDecimalNumber(decimal: roundedValue).doubleValue
            XCTAssertEqual(roundedDoubleValue, expectedValue, accuracy: 0.000000000000000001)
        }
    }
}
