//
//  APIListTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import XCTest
import BlockchainSdk
@testable import Tangem

final class APIListTests: XCTestCase {
    func testParseAPIList() throws {
        let apiListProvider = CommonAPIListProvider()
        XCTAssertNoThrow(try apiListProvider.parseLocalFileForTest())
    }

    func testLocalAPIListFulfillment() throws {
        let apiListProvider = CommonAPIListProvider()
        let apiList = try apiListProvider.parseLocalFileForTest()

        XCTAssert(!apiList.isEmpty, "Local API list shouldn't be empty")
        Blockchain.allMainnetCases.forEach {
            let providers = apiList[$0.networkId] ?? []

            switch $0 {
            // This blockchains didn't use API list to setup providers, so we can skip them
            case .binance, .ducatus:
                return
            default:
                break
            }

            if providers.isEmpty {
                XCTFail("No providers were added in local API list for \($0.displayName)")
                return
            }
        }
    }
}
