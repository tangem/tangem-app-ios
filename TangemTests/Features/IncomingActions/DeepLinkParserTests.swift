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
    var parser: DeepLinkURLParser!

    override func setUp() {
        super.setUp()
        parser = DeepLinkURLParser()
    }

    override func tearDown() {
        parser = nil
        super.tearDown()
    }

    // MARK: - Valid Deep Links

    func testParseMainHost() {
        let url = URL(string: "tangem://main")!
        let action = parser.parse(url)
        XCTAssertEqual(action, .navigation(.main))
    }

    func testParseReferralHost() {
        let url = URL(string: "tangem://referral")!
        let action = parser.parse(url)
        XCTAssertEqual(action, .navigation(.referral))
    }

    func testParseBuyHost() {
        let url = URL(string: "tangem://buy")!
        let action = parser.parse(url)
        XCTAssertEqual(action, .navigation(.buy))
    }

    func testParseSellHost() {
        let url = URL(string: "tangem://sell")!
        let action = parser.parse(url)
        XCTAssertEqual(action, .navigation(.sell))
    }

    func testParseMarketsHost() {
        let url = URL(string: "tangem://markets")!
        let action = parser.parse(url)
        XCTAssertEqual(action, .navigation(.markets))
    }

    func testParseTokenChartWithSymbol() {
        let url = URL(string: "tangem://token_chart?symbol=BTC")!
        let action = parser.parse(url)
        XCTAssertEqual(action, .navigation(.tokenChart(tokenName: "BTC")))
    }

    func testParseStakingWithSymbol() {
        let url = URL(string: "tangem://staking?symbol=ETH")!
        let action = parser.parse(url)
        XCTAssertEqual(action, .navigation(.staking(tokenName: "ETH")))
    }

    func testParseTokenWithSymbolNetwork() {
        let url = URL(string: "tangem://token?symbol=USDT&network=solana")!
        let action = parser.parse(url)
        XCTAssertEqual(action, .navigation(.token(tokenName: "USDT", network: "solana")))
    }

    // MARK: - Missing Parameters

    func testTokenMissingParameters() {
        let url = URL(string: "tangem://token")!
        let action = parser.parse(url)
        // Defaults to empty strings for symbol and network
        XCTAssertEqual(action, .navigation(.token(tokenName: "", network: "")))
    }

    func testTokenChartMissingSymbol() {
        let url = URL(string: "tangem://token_chart")!
        let action = parser.parse(url)
        XCTAssertEqual(action, .navigation(.tokenChart(tokenName: "")))
    }

    func testStakingMissingSymbol() {
        let url = URL(string: "tangem://staking")!
        let action = parser.parse(url)
        XCTAssertEqual(action, .navigation(.staking(tokenName: "")))
    }

    // MARK: - Invalid Scheme and Host

    func testInvalidScheme() {
        let url = URL(string: "http://main")!
        let action = parser.parse(url)
        XCTAssertNil(action)
    }

    func testInvalidHost() {
        let url = URL(string: "tangem://unknown")!
        let action = parser.parse(url)
        XCTAssertNil(action)
    }
}
