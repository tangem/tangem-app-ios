//
//  MainScreenUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest

final class MainScreenUITests: BaseTestCase {
    private let token = "Polygon"

    func testTokenListChanges_WhenSwitchingBetweenCards() {
        setAllureId(177)
        launchApp(tangemApiType: .mock)

        let mainScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)

        let card1Tokens = mainScreen.getTokensOrder()

        // Switch to reduced token list for the second card
        setupWireMockScenarios([ScenarioConfig(name: "user_tokens_api", initialState: "ReducedTokens")])

        mainScreen
            .addNewWallet(name: .wallet)
            .verifyTokensOrderChanged(from: card1Tokens)
    }

    func testCustomDerivationTokenAndNetworkIcon_DisplayedWithIndicator() {
        setAllureId(180)

        let customDerivationScenario = ScenarioConfig(
            name: "user_tokens_api",
            initialState: "CustomDerivation"
        )

        launchApp(
            tangemApiType: .mock,
            scenarios: [customDerivationScenario]
        )

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .verifyTokenExists("Myria")
            .verifyTokenExists("Ethereum")
            .verifyCustomTokenIndicatorExists(for: "Myria")
    }

    // MARK: - Hide Token Tests

    func testHideToken_TokenNotDispayedOnMain() {
        setAllureId(880)
        launchApp(tangemApiType: .mock)

        let mainScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(token)
            .hideToken(name: token)

        mainScreen.validateTokenNotExists(token)
    }

    func testScanWallet2_DeveloperCardBannerDisplayed() {
        setAllureId(898)
        launchApp()

        let mainScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)

        mainScreen.waitDeveloperCardBannerExists()
    }

    func testScanCardWithReleaseFirmware_DeveloperCardBannerNotDisplayed() {
        setAllureId(3991)
        launchApp()

        let mainScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .ring)

        mainScreen.waitDeveloperCardBannerNotExists()
    }

    func testUnavailableNetworksWarning_DisplayedWithMessage() {
        setAllureId(184)

        let missingDerivationScenario = ScenarioConfig(
            name: "user_tokens_api",
            initialState: "MissingDerivation"
        )

        launchApp(
            tangemApiType: .mock,
            scenarios: [missingDerivationScenario]
        )

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .waitForSynchronizeAddressesButtonExists()
            .verifyMissingDerivationNotificationHasMessage()
    }
}
