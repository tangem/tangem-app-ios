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
}
