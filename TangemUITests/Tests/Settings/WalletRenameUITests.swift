//
//  WalletRenameUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class WalletRenameUITests: BaseTestCase {
    private let initialWalletName = "Wallet"
    private let newWalletName = "Tangem QA"

    func testRenameWallet_NewNameVisibleEverywhere() {
        setAllureId(2264)
        launchApp(tangemApiType: .mock)

        let mainScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)

        mainScreen
            .openDetails()
            .openWalletSettings(for: initialWalletName)
            .tapRenameWallet()
            .clearName()
            .enterName(newWalletName)
            .save()
            .verifyWalletNameDisplayed(newWalletName)

        let detailsScreen = CardSettingsScreen(app).goBackToDetails()
        let renamedWalletButton = app.buttons[
            WalletSettingsAccessibilityIdentifiers.walletSettingsButton(name: newWalletName)
        ]
        XCTAssertTrue(
            renamedWalletButton.waitForExistence(timeout: .robustUIUpdate),
            "Renamed wallet row '\(newWalletName)' should be visible on Details"
        )

        detailsScreen
            .goBackToMain()
        let headerName = app.staticTexts.matching(NSPredicate(format: "label == %@", newWalletName)).firstMatch
        XCTAssertTrue(
            headerName.waitForExistence(timeout: .robustUIUpdate),
            "New wallet name '\(newWalletName)' should be visible on Main"
        )
    }
}
