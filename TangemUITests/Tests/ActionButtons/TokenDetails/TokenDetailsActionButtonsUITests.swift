//
//  TokenDetailsActionButtonsUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest

final class TokenDetailsActionButtonsUITests: BaseTestCase {
    func testTokenDetailsActionButtons_Bitcoin_StateValidation() {
        setAllureId(594)
        launchApp(
            tangemApiType: .mock,
            clearStorage: true
        )

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .validate(cardType: .wallet2)
            .tapToken("Ethereum")
            .waitForActionButtons()
    }

    func testTokenDetailsSwapButton_ShowErrorAlert() {
        setAllureId(4461)
        let expressApiErrorScenario = ScenarioConfig(
            name: "express_api_assets",
            initialState: "Error"
        )

        launchApp(
            tangemApiType: .mock,
            expressApiType: .mock,
            clearStorage: true,
            scenarios: [expressApiErrorScenario]
        )

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .validate(cardType: .wallet2)
            .tapToken("Polygon")
            .tapSwapButton()

        waitAndDismissErrorAlert(actionName: "Swap")
    }

    func testTokenDetailsSwapButton_ShowErrorUnreachable() {
        setAllureId(4460)

        launchApp(
            tangemApiType: .mock,
            expressApiType: .mock,
            clearStorage: true
        )

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .validate(cardType: .wallet2)
            .tapToken("POL (ex-MATIC)")
            .tapSwapButton()

        waitAndDismissErrorAlert(actionName: "Swap")
    }

    func testTokenDetailsSwapButton_ShowSwapScreen() {
        setAllureId(4459)

        launchApp(
            tangemApiType: .mock,
            expressApiType: .mock,
            clearStorage: true
        )

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .validate(cardType: .wallet2)
            .tapToken("Ethereum")
            .tapSwapButton()
            .closeStoriesIfNeeded()
            .validateSwapScreenDisplayed()
            .waitFromTokenDisplayed(tokenSymbol: "ETH")
    }

    func testTokenDetailsReceive_ShowsQRCode() {
        setAllureId(3590)

        launchApp(
            tangemApiType: .mock,
            clearStorage: true
        )

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken("Bitcoin")
            .waitForActionButtons()
            .tapReceiveButton()
            .tapUnderstoodIfNeeded()
            .validateShowQRCodeButtonDisplayed()
            .tapShowQRCode()
            .waitForDisplay()
    }

    func testTokenDetailsActionButtons_SendUnavailable() {
        setAllureId(593)
        launchApp(
            tangemApiType: .mock,
            clearStorage: true
        )

        let tokenScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .validate(cardType: .wallet2)
            .tapToken("Bitcoin")
            .waitForActionButtons()

        tokenScreen
            .tapSendButton()

        waitAndDismissErrorAlert(
            actionName: "Send",
            expectedMessage: "You do not have funds to send"
        )
    }
}
