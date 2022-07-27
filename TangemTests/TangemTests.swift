//
//  TangemTests.swift
//  TangemTests
//
//  Created by Alexander Osokin on 15.07.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import XCTest
import TangemSdk
import BlockchainSdk
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
}
