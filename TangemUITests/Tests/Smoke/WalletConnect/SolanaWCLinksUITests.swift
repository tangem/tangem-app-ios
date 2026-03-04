//
//  SolanaWCLinksUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import XCTest

final class SolanaWCLinksUITests: BaseTestCase {
    let safariHelper = SafariHelper()
    let qaToolsClient = QAToolsClient()
    private var wcURI: String!

    func testOpenTangemAppFromSafari_ShowsWalletConnectSheet() throws {
        setAllureId(4025)

        getWcURI()
        let userTokensScenario = ScenarioConfig(
            name: "user_tokens_api",
            initialState: "Solana"
        )
        setupWireMockScenarios([userTokensScenario])
        app.launchEnvironment = ["UITEST": "1"]
        app.launch()
        CreateWalletSelectorScreen(app)
            .acceptToSIfNeeded()
            .scanMockWallet(name: .wallet2)
            .validate(cardType: .wallet2)
        app.terminate()

        safariHelper.safari.launch()

        safariHelper.openDeeplink(wcURI)
        safariHelper.tapOpenTangemApp()

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
        setAllureId(4023)

        getWcURI()
        let userTokensScenario = ScenarioConfig(
            name: "user_tokens_api",
            initialState: "Solana"
        )
        launchApp(
            tangemApiType: .mock,
            scenarios: [userTokensScenario]
        )
        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)

        safariHelper.safari.launch()
        safariHelper.openDeeplink(wcURI)
        safariHelper.tapOpenTangemApp()

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
        setAllureId(4024)

        getWcURI()
        let userTokensScenario = ScenarioConfig(
            name: "user_tokens_api",
            initialState: "Solana"
        )
        launchApp(
            tangemApiType: .mock,
            scenarios: [userTokensScenario]
        )
        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .openDetails()

        safariHelper.safari.launch()
        safariHelper.openDeeplink(wcURI)
        safariHelper.tapOpenTangemApp()

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
        setAllureId(4026)

        getWcURI()
        // Remove the scheme prefix for paste operation
        let uriWithoutScheme = wcURI.replacingOccurrences(of: "\(WCURIScheme.appTangem.rawValue)?uri=", with: "")
        UIPasteboard.general.string = uriWithoutScheme
        let userTokensScenario = ScenarioConfig(
            name: "user_tokens_api",
            initialState: "Solana"
        )
        launchApp(
            tangemApiType: .mock,
            scenarios: [userTokensScenario]
        )

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
        wcURI = qaToolsClient.getWCURISync(network: .solana, uriScheme: .appTangem)

        XCTContext.runActivity(named: "Log received WC URI: \(wcURI ?? "nil")") { _ in
            XCTAssert(!wcURI.isEmpty, "WC URI is empty")
        }
    }
}
