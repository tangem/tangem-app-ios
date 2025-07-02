//
//  ScanMockWalletUITests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//
import XCTest

final class ScanMockWalletUITests: BaseTestCase {
    lazy var tosPage = ToSScreen(app)

    func testScanMockWallet_ShouldShowMainScreen() {
        launchApp(resetToS: true)

        tosPage
            .acceptAgreement()
            .scanMockWallet(name: .wallet2)
            .validate()
    }
}
