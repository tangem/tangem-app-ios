//
//  ToSUITests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//
import XCTest

final class ToSUITests: BaseTestCase {
    lazy var tosPage = ToSScreen(app)

    func testAcceptToSAndScanWallet_ShouldShowMainScreen() {
        setAllureId(3573)
        launchApp(skipToS: false)

        tosPage
            .acceptAgreement()
            .scanMockWallet(name: .wallet2)
            .validate(cardType: .wallet2)
    }

    func testAcceptToSAfterAppRelaunch_ShouldShowMainScreen() {
        setAllureId(3574)
        launchApp(tangemApiType: .mock, skipToS: false)

        tosPage
            .waitForToSAcceptButton()

        app.terminate()

        app.launch()
        tosPage
            .acceptAgreement()
            .scanMockWallet(name: .wallet2)
            .validate(cardType: .wallet2)
    }
}
