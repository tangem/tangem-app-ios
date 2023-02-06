//
//  IncomingActionsTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
@testable import Tangem

class IncomingActionsTests: XCTestCase {
    func testIntents() {
        let parser = IncomingActionParser()
        XCTAssertFalse(parser.handleIntent("AnyWrongIntent"))
        XCTAssertTrue(parser.handleIntent("ScanTangemCardIntent"))
    }

    func testDeeplinks() {
        let parser = IncomingActionParser()
        XCTAssertFalse(parser.handleDeeplink(URL(string: "https://google.com")!))
        XCTAssertFalse(parser.handleDeeplink(URL(string: "test://")!))
        XCTAssertFalse(parser.handleDeeplink(URL(string: "https://tangem.com/abc")!))
        XCTAssertFalse(parser.handleDeeplink(URL(string: "https://app.tangem.com/abc")!))
        XCTAssertFalse(parser.handleDeeplink(URL(string: "tangem://abc")!))
        XCTAssertFalse(parser.handleDeeplink(URL(string: "tangem://ndef")!))
        XCTAssertFalse(parser.handleDeeplink(URL(string: "https://tangem.com/ndef")!))
        XCTAssertFalse(parser.handleDeeplink(URL(string: "tangem://abc?uri=wc:12e2e015-0ae0-4bac-9d2b-b67244388eb9@1?bridge=https%3A%2F%2Fw.bridge.walletconnect.org&key=aede7f2aedde949ef1812ac624362a53737dd57acdce2d0e44b247a109d87d98")!))
        XCTAssertFalse(parser.handleDeeplink(URL(string: "https://tangem.com/redirect")!))

        XCTAssertTrue(parser.handleDeeplink(URL(string: "https://app.tangem.com/ndef")!))
        XCTAssertTrue(parser.handleDeeplink(URL(string: "tangem://wc?uri=wc:12e2e015-0ae0-4bac-9d2b-b67244388eb9@1?bridge=https%3A%2F%2Fw.bridge.walletconnect.org&key=aede7f2aedde949ef1812ac624362a53737dd57acdce2d0e44b247a109d87d98")!))
        XCTAssertTrue(parser.handleDeeplink(URL(string: "https://tangem.com/wc?uri=wc:8ad9144fec726c592b3bae26e2fa797e61b08d523fe9036ac7fe4f3c54b7b9f4@2?relay-protocol=irn&symKey=cc2f1426571a59111059b7661c6aecadc08784d299a2dce36c576844e40d6c81")!))
        XCTAssertTrue(parser.handleDeeplink(URL(string: "https://app.tangem.com/wc?uri=wc:5ae26da3-e0e9-4dd7-bc35-380d6f77afdb@1?bridge=https%3A%2F%2Fo.bridge.walletconnect.org&key=33156d17ff3aa7384f803501691e7a2a3205edbc03f2dfa22d4ee3e4db036348")!))
    }

    func testWC2Link() {
        let parser = WalletConnectURLParser()
        let uri = parser.parse(URL(string: "tangem://wc?uri=wc:8ad9144fec726c592b3bae26e2fa797e61b08d523fe9036ac7fe4f3c54b7b9f4@2?relay-protocol=irn&symKey=cc2f1426571a59111059b7661c6aecadc08784d299a2dce36c576844e40d6c81")!)

        switch uri {
        case .v2:
            XCTAssertTrue(true)
        default:
            XCTAssertTrue(false)
        }
    }

    func testWC2LinkFromString() {
        let parser = WalletConnectURLParser()
        let uri = parser.parse("wc:8ad9144fec726c592b3bae26e2fa797e61b08d523fe9036ac7fe4f3c54b7b9f4@2?relay-protocol=irn&symKey=cc2f1426571a59111059b7661c6aecadc08784d299a2dce36c576844e40d6c81")

        switch uri {
        case .v2:
            XCTAssertTrue(true)
        default:
            XCTAssertTrue(false)
        }
    }

    func testWC1Link() {
        let parser = WalletConnectURLParser()
        let uri = parser.parse(URL(string: "https://app.tangem.com/wc?uri=wc:5ae26da3-e0e9-4dd7-bc35-380d6f77afdb@1?bridge=https%3A%2F%2Fo.bridge.walletconnect.org&key=33156d17ff3aa7384f803501691e7a2a3205edbc03f2dfa22d4ee3e4db036348")!)

        switch uri {
        case .v1:
            XCTAssertTrue(true)
        default:
            XCTAssertTrue(false)
        }
    }

    func testWC1LinkFromString() {
        let parser = WalletConnectURLParser()
        let uri = parser.parse("wc:5ae26da3-e0e9-4dd7-bc35-380d6f77afdb@1?bridge=https%3A%2F%2Fo.bridge.walletconnect.org&key=33156d17ff3aa7384f803501691e7a2a3205edbc03f2dfa22d4ee3e4db036348")

        switch uri {
        case .v1:
            XCTAssertTrue(true)
        default:
            XCTAssertTrue(false)
        }
    }
}
