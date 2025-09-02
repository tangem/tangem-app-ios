//
//  WCLinksUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import XCTest

final class WCLinksUITests: BaseTestCase {
    let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
    let qaToolsClient = QAToolsClient()
    private var wcURI: String!

    override func setUp() {
        super.setUp()
        wcURI = qaToolsClient.getWCURISync()
    }

    func testOpenTangemAppFromSafari_ShowsWalletConnectSheet() throws {
        setAllureId(3957)

        app.launch()
        StoriesScreen(app)
            .acceptToSIfNeeded()
            .allowPushNotificationsIfNeeded()
            .scanMockWallet(name: .wallet2)
            .organizeTokens()
        app.terminate()

        safari.launch()

        openDeeplinkInSafari(wcURI)

        app.activate()

        StoriesScreen(app)
            .scanMockWallet(name: .wallet2)

        WalletConnectSheet(app)
            .validate()
            .approveConnection()

        MainScreen(app)
            .openDetails()
            .openWalletConnections()
            .tapFirstDAppRow()
            .validate()
            .disconnectApp()
            .validateEmptyState()
    }

    func testOpenWalletConnectSheetFromMainScreen_ConnectionEstablished() throws {
        setAllureId(3958)

        launchApp()
        StoriesScreen(app)
            .scanMockWallet(name: .wallet2)

        safari.launch()
        openDeeplinkInSafari(wcURI)

        WalletConnectSheet(app)
            .validate()
            .approveConnection()

        MainScreen(app)
            .openDetails()
            .openWalletConnections()
            .tapFirstDAppRow()
            .validate()
            .disconnectApp()
            .validateEmptyState()
    }

    func testOpenWalletConnectSheetFromDetailsScreen_ConnectionEstablished() throws {
        setAllureId(3959)

        launchApp()
        StoriesScreen(app)
            .scanMockWallet(name: .wallet2)
            .openDetails()

        safari.launch()
        openDeeplinkInSafari(wcURI)

        WalletConnectSheet(app)
            .validate()
            .approveConnection()

        DetailsScreen(app)
            .openWalletConnections()
            .tapFirstDAppRow()
            .validate()
            .disconnectApp()
            .validateEmptyState()
    }

    private func openDeeplinkInSafari(_ deeplink: String) {
        // Open address bar
        let urlField = safari.textFields["Address"]
        XCTAssertTrue(urlField.waitForExistence(timeout: 5), "Address bar not found")
        urlField.tap()
        safari.buttons["ClearTextButton"].tap()

        // Insert deeplink
        UIPasteboard.general.string = deeplink
        urlField.doubleTap()
        safari.menuItems["Paste and Go"].tap()

        // Wait for system alert (permission to open another app)
        let openButton = safari.buttons["Open"]
        if openButton.waitForExistence(timeout: 5) {
            openButton.tap()
        }
    }
}
