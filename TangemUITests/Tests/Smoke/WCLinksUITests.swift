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

        XCTContext.runActivity(named: "Log received WC URI: \(wcURI ?? "nil")") { _ in
            XCTAssert(!wcURI.isEmpty, "WC URI is empty")
        }
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
            .waitForConnectionProposalBottomSheetToBeVisible()
            .tapConnectionButton()

        MainScreen(app)
            .openDetails()
            .openWalletConnections()
            .tapFirstDAppRow()
            .waitForConnectedAppBottomSheetToBeVisible()
            .tapDisconnectButton()
            .waitForEmptyConnectionsList()
    }

    func testOpenWalletConnectSheetFromMainScreen_ConnectionEstablished() throws {
        setAllureId(3958)

        launchApp()
        StoriesScreen(app)
            .scanMockWallet(name: .wallet2)

        safari.launch()
        openDeeplinkInSafari(wcURI)

        WalletConnectSheet(app)
            .waitForConnectionProposalBottomSheetToBeVisible()
            .tapConnectionButton()

        MainScreen(app)
            .openDetails()
            .openWalletConnections()
            .tapFirstDAppRow()
            .waitForConnectedAppBottomSheetToBeVisible()
            .tapDisconnectButton()
            .waitForEmptyConnectionsList()
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
            .waitForConnectionProposalBottomSheetToBeVisible()
            .tapConnectionButton()

        DetailsScreen(app)
            .openWalletConnections()
            .tapFirstDAppRow()
            .waitForConnectedAppBottomSheetToBeVisible()
            .tapDisconnectButton()
            .waitForEmptyConnectionsList()
    }

    func testOpenNewConnectionFromDetailsScreen_TapPasteButton() throws {
        setAllureId(887)

        UIPasteboard.general.string = wcURI.replacingOccurrences(of: "tangem://wc?uri=", with: "")
        launchApp()

        StoriesScreen(app)
            .scanMockWallet(name: .wallet2)
            .openDetails()

        DetailsScreen(app)
            .openWalletConnections()
            .tapNewConnection()
            .waitForQRScannerScreenToBeVisible()
            .tapPasteButton()
            .waitForConnectionProposalBottomSheetToBeVisible()
            .tapConnectionButton()

        WalletConnectionsScreen(app)
            .tapFirstDAppRow()
            .waitForConnectedAppBottomSheetToBeVisible()
            .tapDisconnectButton()
            .waitForEmptyConnectionsList()
    }

    private func openDeeplinkInSafari(_ deeplink: String) {
        let clearButton = safari.buttons["ClearTextButton"]

        // Open address bar
        let urlField = safari.textFields["Address"]
        XCTAssertTrue(urlField.waitForExistence(timeout: 5), "Address bar not found")
        urlField.tap()

        if clearButton.isHittable {
            clearButton.tap()
        }

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
