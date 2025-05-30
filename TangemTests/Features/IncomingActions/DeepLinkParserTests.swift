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

    // MARK: – Valid scheme & hosts

    func testParse_mainHost_returnsMainAction() {
        let url = URL(string: "tangem://main")!
        let action = parser.parse(url)
        XCTAssertEqual(action, .navigation(.main))
    }

    func testParse_referralHost_returnsReferralAction() {
        let url = URL(string: "tangem://referral")!
        XCTAssertEqual(parser.parse(url), .navigation(.referral))
    }

    func testParse_buyHost_returnsBuyAction() {
        let url = URL(string: "tangem://buy")!
        XCTAssertEqual(parser.parse(url), .navigation(.buy))
    }

    func testParse_sellHost_returnsSellAction() {
        let url = URL(string: "tangem://sell")!
        XCTAssertEqual(parser.parse(url), .navigation(.sell))
    }

    func testParse_marketsHost_returnsMarketsAction() {
        let url = URL(string: "tangem://markets")!
        XCTAssertEqual(parser.parse(url), .navigation(.markets))
    }

    // MARK: – Token navigation

    func testParse_tokenHost_withSymbolAndNetwork_returnsTokenAction() {
        let url = URL(string: "tangem://token?token_symbol=BTC&network=mainnet")!
        XCTAssertEqual(
            parser.parse(url),
            .navigation(.token(tokenName: "BTC", network: "mainnet"))
        )
    }

    func testParse_tokenHost_withSymbolOnly_returnsTokenActionWithEmptyNetwork() {
        let url = URL(string: "tangem://token?token_symbol=ETH")!
        XCTAssertEqual(
            parser.parse(url),
            .navigation(.token(tokenName: "ETH", network: ""))
        )
    }

    func testParse_tokenHost_missingSymbol_returnsNil() {
        let url = URL(string: "tangem://token?network=solana")!
        XCTAssertNil(parser.parse(url))
    }

    // MARK: – Token chart

    func testParse_tokenChartHost_withBothParams_returnsTokenChartAction() {
        let url = URL(string: "tangem://token_chart?token_symbol=USDT&token_id=42")!
        XCTAssertEqual(
            parser.parse(url),
            .navigation(.tokenChart(tokenSymbol: "USDT", tokenId: "42"))
        )
    }

    func testParse_tokenChartHost_missingSymbol_returnsNil() {
        let url = URL(string: "tangem://token_chart?token_id=42")!
        XCTAssertNil(parser.parse(url))
    }

    func testParse_tokenChartHost_missingId_returnsNil() {
        let url = URL(string: "tangem://token_chart?token_symbol=USDT")!
        XCTAssertNil(parser.parse(url))
    }

    // MARK: – Staking

    func testParse_stakingHost_withSymbol_returnsStakingAction() {
        let url = URL(string: "tangem://staking?token_symbol=DOT")!
        XCTAssertEqual(
            parser.parse(url),
            .navigation(.staking(tokenName: "DOT"))
        )
    }

    func testParse_stakingHost_missingSymbol_returnsNil() {
        let url = URL(string: "tangem://staking")!
        XCTAssertNil(parser.parse(url))
    }

    // MARK: – Invalid cases

    func testParse_unknownHost_returnsNil() {
        let url = URL(string: "tangem://foobar")!
        XCTAssertNil(parser.parse(url))
    }

    func testParse_invalidScheme_returnsNil() {
        let url = URL(string: "https://token?token_symbol=BTC")!
        XCTAssertNil(parser.parse(url))
    }

    func testParse_emptyURL_returnsNil() {
        let url = URL(string: "") // malformed
        XCTAssertNil(url.flatMap(parser.parse))
    }

    func testParse_queryParameterCaseSensitivity() {
        // ensure name matching is exact
        let url = URL(string: "tangem://token?TOKEN_SYMBOL=BTC")!
        XCTAssertNil(parser.parse(url))
    }

    func testParse_extraQueryItems_areIgnored() {
        let url = URL(string: "tangem://token?token_symbol=ADA&foo=bar")!
        XCTAssertEqual(
            parser.parse(url),
            .navigation(.token(tokenName: "ADA", network: ""))
        )
    }
}
