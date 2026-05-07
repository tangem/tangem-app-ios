//
//  WalletConnectPayLinkParserTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
@testable import Tangem

final class WalletConnectPayLinkParserTests: XCTestCase {
    private let parser = WalletConnectPayLinkParser(isFeatureAvailable: { true })

    func testPayWalletConnectURL() {
        XCTAssertEqual(
            parser.parse("https://pay.walletconnect.com/?pid=pay_123")?.rawValue,
            "https://pay.walletconnect.com/?pid=pay_123"
        )
    }

    func testBarePaymentId() {
        XCTAssertEqual(parser.parse("pay_123")?.rawValue, "pay_123")
    }

    func testWalletConnectURIWithPayParameter() {
        let uri = "wc:abc@2?pay=https%3A%2F%2Fpay.walletconnect.com%2F%3Fpid%3Dpay_123"
        XCTAssertEqual(parser.parse(uri)?.rawValue, uri)
    }

    func testRegularWalletConnectURIIsRejected() {
        let uri = "wc:abc123@2?relay-protocol=irn&symKey=xyz"
        XCTAssertNil(parser.parse(uri))
    }
}
