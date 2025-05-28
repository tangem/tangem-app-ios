//
//  DeepLinkParserTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
@testable import Tangem

final class DeepLinkURLParserTests: XCTestCase {
    private let parser = DeepLinkURLParser()

    func testMainScreen() {
        let url = URL(string: "tangem://main")!
        let action = parser.parse(url)
        XCTAssertEqual(action, .navigation(.main))
    }

    func testTokenScreenWithoutNetwork() {
        let url = URL(string: "tangem://token?symbol=TON")!
        let action = parser.parse(url)
        XCTAssertEqual(action, .navigation(.token(symbol: "TON", network: nil)))
    }

    func testTokenScreenWithNetwork() {
        let url = URL(string: "tangem://token?symbol=USDT&network=TRC20")!
        let action = parser.parse(url)
        XCTAssertEqual(action, .navigation(.token(symbol: "USDT", network: "TRC20")))
    }

    func testReferralScreen() {
        let url = URL(string: "tangem://referral")!
        let action = parser.parse(url)
        XCTAssertEqual(action, .navigation(.referral))
    }

    func testBuyScreen() {
        let url = URL(string: "tangem://buy")!
        let action = parser.parse(url)
        XCTAssertEqual(action, .navigation(.buy))
    }

    func testSellScreen() {
        let url = URL(string: "tangem://sell")!
        let action = parser.parse(url)
        XCTAssertEqual(action, .navigation(.sell))
    }

    func testMarketsScreen() {
        let url = URL(string: "tangem://markets")!
        let action = parser.parse(url)
        XCTAssertEqual(action, .navigation(.markets))
    }

    func testTokenChart() {
        let url = URL(string: "tangem://token_chart?symbol=BTC")!
        let action = parser.parse(url)
        XCTAssertEqual(action, .navigation(.tokenChart(symbol: "BTC")))
    }

    func testStakingScreen() {
        let url = URL(string: "tangem://staking?symbol=TRX")!
        let action = parser.parse(url)
        XCTAssertEqual(action, .navigation(.staking(symbol: "TRX")))
    }

    func testInvalidScheme() {
        let url = URL(string: "http://example.com")!
        XCTAssertNil(parser.parse(url))
    }

    func testUnknownHost() {
        let url = URL(string: "tangem://unknown?foo=bar")!
        XCTAssertNil(parser.parse(url))
    }
}
