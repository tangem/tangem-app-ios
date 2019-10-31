//
//  TangemSdkTests.swift
//  TangemSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import XCTest
@testable import TangemSdk

class UtilsTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testGeneratePrivateKey() {
           let privateKey = CryptoUtils.generateRandomBytes(count: 32)
           XCTAssertNotNil(privateKey)
           XCTAssert(privateKey!.count == 32)
    }
    
    func testSecp256k1Sign() {
        let privateKey = Data(hex: "fd230007d4a39352f50d8c481456c1f86ddc5ff155df170af0100a62269852f0")
        let publicKey = Data(hex: "0432f507f6a3029028faa5913838c50f5ff3355b9b000b51889d03a2bdb96570cd750e8187482a27ca9d2dd0c92c632155d0384521ed406753c9883621ad0da68c")
        
        let dummyData = Data(repeating: UInt8(1), count: 64)
        let signature = CryptoUtils.signSecp256k1(dummyData, with: privateKey)
        XCTAssertNotNil(signature)
        
        let verify = CryptoUtils.vefify(curve: .secp256k1, publicKey: publicKey, message: dummyData, signature: signature!)
        XCTAssertNotNil(verify)
        XCTAssert(verify! == true)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
}
