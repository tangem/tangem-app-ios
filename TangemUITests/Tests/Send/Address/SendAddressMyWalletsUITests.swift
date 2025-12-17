//
//  SendAddressMyWalletsUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest

final class SendAddressMyWalletsUITests: BaseTestCase {
    func testAddressScreen_MyWalletsBlockDisplaysOwnAddressOnUTXONetwork() {
        setAllureId(4737)

        openDogecoinAddressScreen()
            .waitForMyWalletsBlockDisplayed()
    }

    func testAddressScreen_SelectMyWalletAddressOpensConfirmationScreen() {
        setAllureId(4579)

        let sendScreen = openDogecoinAddressScreen()

        sendScreen
            .waitForMyWalletsBlockDisplayed()
            .waitForWalletAddress(DogecoinAddressTestData.walletAddress)
            .selectWalletCell(at: 0)

        SendSummaryScreen(app)
            .waitForAmountValue(DogecoinAddressTestData.sendAmount)
    }

    func testAddressScreen_MyWalletsBlockNotDisplayedWhenBiometricsDisabled() {
        setAllureId(4599)

        let tokenName = "Ethereum"
        let sendAmount = "1"

        launchApp(
            tangemApiType: .mock,
            clearStorage: true
        )

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .longPressToken(tokenName)
            .waitForActionButtons()
            .tapSend()
            .waitForDisplay()
            .enterAmount(sendAmount)
            .tapNextButton()
            .waitForMyWalletsBlockNotDisplayed()
    }
}

// MARK: - Helpers

private extension SendAddressMyWalletsUITests {
    func openDogecoinAddressScreen() -> SendScreen {
        let dogecoinScenario = ScenarioConfig(
            name: "user_tokens_api",
            initialState: DogecoinAddressTestData.tokenName
        )

        let dogecoinQuotesScenario = ScenarioConfig(
            name: "quotes_api",
            initialState: DogecoinAddressTestData.tokenName
        )

        let txHistoryScenario = ScenarioConfig(
            name: DogecoinAddressTestData.txHistoryScenarioName,
            initialState: DogecoinAddressTestData.txHistoryScenarioState
        )

        launchApp(
            tangemApiType: .mock,
            scenarios: [dogecoinScenario, dogecoinQuotesScenario, txHistoryScenario]
        )

        return CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .longPressToken(DogecoinAddressTestData.tokenName)
            .waitForActionButtons()
            .tapSend()
            .waitForDisplay()
            .enterAmount(DogecoinAddressTestData.sendAmount)
            .tapNextButton()
    }
}

private enum DogecoinAddressTestData {
    static let tokenName = "Dogecoin"
    static let sendAmount = "1"
    static let txHistoryScenarioName = "dogecoin_tx_history"
    static let txHistoryScenarioState = "OutgoingTransaction"
    static let walletAddress = "DDxaZXJryq1ZuoRhnfV3gWZE9YpXvsSxgW"
}
