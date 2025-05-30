//
//  MainTest.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//
import XCTest

final class MainTest: CommonTests {
    lazy var storiesPage = StoriesPage(app)
    lazy var mainPage = MainPage(app)
    lazy var tosPage = ToSPage(app)

    func testScanWallet2() {
        launchApp()

        testStep("Accept Terms of Service and skip additional setup") {
            tosPage.acceptButton.tap()
            tosPage.laterButton.tap()
        }

        checkCondition(
            "Verify Scan button is visible",
            storiesPage.scanButton.waitForState(state: .exists, for: .quickNetworkRequest)
        )

        testStep("Scanning wallet by tapping scan button and selecting mock wallet two") {
            storiesPage.scanButton.tap()
            storiesPage.cardMockWalletTwo.tap()
        }

        checkCondition(
            "Verify Buy button is visible",
            mainPage.buyTitle.waitForState(state: .exists, for: .quickNetworkRequest)
        )

        checkCondition(
            "Verify Exchange button is visible",
            mainPage.exchangeTitle.exists
        )

        checkCondition(
            "Verify Sell button is visible",
            mainPage.sellTitle.exists
        )
    }
}
