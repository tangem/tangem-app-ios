//
//  IntUtilsTests.swift
//  TangemSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
@testable import TangemSdk

class IntUtilsTests: XCTestCase {
    func testFromHexConversion() {
        let testData = Data(hex: "9569")
        XCTAssertEqual(38249, Int(hexData: testData))
    }
    
    func testToByteConversion() {
        XCTAssertEqual(15.byte, Data(hex: "0F"))
        XCTAssertEqual(356.bytes2, Data(hex: "0164"))
        XCTAssertEqual(3456988.bytes4, Data(hex: "0034BFDC"))
        XCTAssertEqual(345698858557552.bytes8, Data(hex: "00013A6949A9E070"))
    }
}
