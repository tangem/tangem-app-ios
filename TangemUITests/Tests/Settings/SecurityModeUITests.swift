//
//  SecurityModeUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class SecurityModeUITests: BaseTestCase {
    func testSecurityMode_Twin_OpensSection() {
        setAllureId(2267)
        launchApp(tangemApiType: .mock)

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .twin)
            .openDetails()
            .openWalletSettings(for: "Twin")
            .openDeviceSettings()
            .scanMockWallet(name: .twin)
            .tapSecurityMode()
            .verifyScreenOpened()
    }

    func testSecurityMode_OtherCards_RowDisabled() {
        setAllureId(9831)
        launchApp(tangemApiType: .mock)

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .openDetails()
            .openWalletSettings(for: "Wallet")
            .openDeviceSettings()
            .scanMockWallet(name: .wallet2)
            .verifySecurityModeRowDisabled()
    }
}
