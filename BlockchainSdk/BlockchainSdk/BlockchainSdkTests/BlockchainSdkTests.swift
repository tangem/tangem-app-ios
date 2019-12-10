//
//  BlockchainSdkTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import XCTest
import TangemSdk
@testable import BlockchainSdk

class BlockchainSdkTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

    func testBase58() {
        let ethalonString = "1NS17iag9jJgTHD1VXjvLCEnZuQ3rJDE9L"
        let testData = Data(hex: "00eb15231dfceb60925886b67d065299925915aeb172c06647")
        let encoded = String(base58: testData)
        XCTAssertEqual(ethalonString, encoded)
    }
    
    func testBtcAddress() {
        let btcAddress = "1PMycacnJaSqwwJqjawXBErnLsZ7RkXUAs"
        let publicKey = Data(hex: "0250863ad64a87ae8a2fe83c1af1a8403cb53f53e486d8511dad8a04887e5b2352")
        XCTAssertEqual(BitcoinAddressFactory().makeAddress(from: publicKey, testnet: false), btcAddress)
    }
}
