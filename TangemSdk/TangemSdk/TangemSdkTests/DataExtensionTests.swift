//
//  UtilsTest.swift
//  TangemSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//
import XCTest
@testable import TangemSdk

class DataExtensionTests: XCTestCase {
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testSha256() {
        let testData = CryptoUtils.generateRandomBytes(count: 256)!
        let shaCryptoKit =  testData.getSha256()
        let shaOld = testData.sha256Old()
        XCTAssertEqual(shaCryptoKit, shaOld)
    }
    
    func testSha512() {
        let testData = CryptoUtils.generateRandomBytes(count: 256)!
        let shaCryptoKit =  testData.getSha512()
        let shaOld = testData.sha512Old()
        XCTAssertEqual(shaCryptoKit, shaOld)
    }
    
    func testSha256CryptoKitPerfomance() {
        let testData = CryptoUtils.generateRandomBytes(count: 256)!
        measure {
            _ = testData.getSha256()
        }
    }
    
    func testSha256OldPerfomance() {
        let testData = CryptoUtils.generateRandomBytes(count: 256)!
        measure {
            _ = testData.sha256Old()
        }
    }
    
    func testBytesConversion() {
        let testData = Data(repeating: UInt8(2), count: 3)
        let testArray = Array.init(repeating: UInt8(2), count: 3)
        XCTAssertEqual(testData.toBytes, testArray)
    }
    
    func testToDateString() {
        let testData = Data(hexString: "07E2071B")
        let testDate = "Jul 27, 2018"
        XCTAssertEqual(testDate, testData.toDate()?.toString())
        
        let testData1 = Data(hexString: "07E2071B1E")
        let testDate1 = "Jul 27, 2018"
        XCTAssertEqual(testDate1, testData1.toDate()?.toString())
        
        XCTAssertNil(Data(hexString: "07E207").toDate())
    }
    
    func testFromHexConversion() {
        let testData = Data([UInt8(0x07),UInt8(0xE2),UInt8(0x07),UInt8(0x1B)])
        XCTAssertEqual(testData, Data(hexString: "07E2071B"))
    }
    
    func testToHexConversion() {
        let testData = Data([UInt8(0x07),UInt8(0xE2),UInt8(0x07),UInt8(0x1B)])
        let hex = testData.asHexString()
        XCTAssertEqual(hex, "07E2071B")
    }
    
    func testToUtf8Conversion() {
        let testData = Data(hexString: "736563703235366B3100")
        let testString = "secp256k1"
        let converted = testData.toUtf8String()
        XCTAssertNotNil(converted)
        XCTAssertEqual(converted!, testString)
    }
    
    func testToIntConversion() {
        let testData = Data(hexString: "00026A03")
        let intData = 158211
        let converted = testData.toInt()
        XCTAssertEqual(converted, intData)
    }
}
