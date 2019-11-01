//
//  ByteUtilsTest.swift
//  TangemSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import XCTest
@testable import TangemSdk

class ByteUtilsTests: XCTestCase {
    func testHexConversion() {
        let testData = UInt8(0x1B)
        let testString = "1B"
        XCTAssert(testString == testData.toHex())
    }
    
    func testInputStream() {
        let data = Data(hex: "00010203040506")
        let inputStream = InputStream(data: data)
        let bytes = inputStream.readBytes(count: 2)
        XCTAssertNotNil(bytes)
        XCTAssert(bytes! == Data(hex: "00010203"))
        let oneMoreByte = inputStream.readByte()
        XCTAssertNotNil(oneMoreByte)
        XCTAssert(bytes! == Data(hex: "04"))
    }
}
