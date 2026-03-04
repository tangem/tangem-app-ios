//
//  EthereumWCLinksUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import XCTest

final class EthereumWCLinksUITests: BaseTestCase {
    let safariHelper = SafariHelper()
    let qaToolsClient = QAToolsClient()
    private var wcURI: String!

    func testOpenTangemAppFromSafari_ShowsWalletConnectSheet() throws {
        setAllureId(3957)

        getWcURI()
        app.launchEnvironment = ["UITEST": "1"]
        app.launch()
        CreateWalletSelectorScreen(app)
            .acceptToSIfNeeded()
            .scanMockWallet(name: .wallet2)
            .validate(cardType: .wallet2)

        app.swipeDown()

        MainScreen(app)
            .organizeTokens()
        app.terminate()

        safariHelper.safari.launch()

        safariHelper.openDeeplink(wcURI)
        safariHelper.tapOpenButton()

        app.activate()

        WelcomeBackScreen(app)
            .selectWalletByName("Wallet")
        CreateWalletSelectorScreen(app)
            .selectWalletFromList(name: .wallet2)

        WalletConnectSheet(app)
            .waitForConnectionProposalBottomSheetToBeVisible()
            .tapConnectionButton()

        MainScreen(app)
            .skipPushNotificationsSetup()
            .openDetails()
            .openWalletConnections()
            .tapFirstDAppRow()
            .waitForConnectedAppBottomSheetToBeVisible()
            .tapDisconnectButton()
            .waitForEmptyConnectionsList()
    }

    func testOpenWalletConnectSheetFromMainScreen_ConnectionEstablished() throws {
        setAllureId(3958)

        getWcURI()
        launchApp(tangemApiType: .mock)
        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)

        safariHelper.safari.launch()
        safariHelper.openDeeplink(wcURI)
        safariHelper.tapOpenButton()

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

        getWcURI()
        launchApp(tangemApiType: .mock)
        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .openDetails()

        safariHelper.safari.launch()
        safariHelper.openDeeplink(wcURI)
        safariHelper.tapOpenButton()

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

        getWcURI()
        UIPasteboard.general.string = wcURI.replacingOccurrences(of: "\(WCURIScheme.tangem.rawValue)?uri=", with: "")
        launchApp(tangemApiType: .mock)

        CreateWalletSelectorScreen(app)
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

    private func getWcURI() {
        wcURI = qaToolsClient.getWCURISync(network: .ethereum, uriScheme: .tangem)

        XCTContext.runActivity(named: "Log received WC URI: \(wcURI ?? "nil")") { _ in
            XCTAssert(!wcURI.isEmpty, "WC URI is empty")
        }
    }
}
