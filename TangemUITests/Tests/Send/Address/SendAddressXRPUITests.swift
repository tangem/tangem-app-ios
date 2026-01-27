//
//  SendAddressXRPUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class SendAddressXRPUITests: BaseTestCase {
    func testAddressScreen_XRPAddressEntry() {
        setAllureId(4590)

        let tokenName = "XRP Ledger"
        let sendAmount = "1"
        let destinationAddress = "rNeY28BPda6jp5N5oESZzd2ZN7eMZy8jNf"

        let xrpScenario = ScenarioConfig(
            name: "user_tokens_api",
            initialState: "XRP"
        )

        launchApp(
            tangemApiType: .mock,
            scenarios: [xrpScenario]
        )

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .longPressToken(tokenName)
            .waitForActionButtons()
            .tapSend()

        SendScreen(app)
            .enterAmount(sendAmount)
            .tapNextButton()
            .enterDestination(destinationAddress)
            .waitForDestinationValue(destinationAddress)
            .waitForAdditionalFieldEnabled()
    }

    func testAddressScreen_XRPAddressEntryWithoutTag() {
        setAllureId(4591)

        let tokenName = "XRP Ledger"
        let sendAmount = "1"
        let destinationAddress = "XVNpatGaPNpPbiAJsQz6ZczZFt97QBbFimbtGZnxBMC7ug9"

        let xrpScenario = ScenarioConfig(
            name: "user_tokens_api",
            initialState: "XRP"
        )

        launchApp(
            tangemApiType: .mock,
            scenarios: [xrpScenario]
        )

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .longPressToken(tokenName)
            .waitForActionButtons()
            .tapSend()

        SendScreen(app)
            .enterAmount(sendAmount)
            .tapNextButton()
            .enterDestination(destinationAddress)
            .waitForDestinationValue(destinationAddress)
            .waitForAdditionalFieldDisabled()
            .waitForAlreadyIncludedText()
            .waitForNextButtonEnabled()
    }

    func testAddressScreen_XRPAddressEntryWithTag() {
        setAllureId(4592)

        let tokenName = "XRP Ledger"
        let sendAmount = "1"
        let destinationAddress = "XVNpatGaPNpPbiAJsQz6ZczZFt97QB6jeQWyCM3uCaDHVix"

        let xrpScenario = ScenarioConfig(
            name: "user_tokens_api",
            initialState: "XRP"
        )

        launchApp(
            tangemApiType: .mock,
            scenarios: [xrpScenario]
        )

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .longPressToken(tokenName)
            .waitForActionButtons()
            .tapSend()

        SendScreen(app)
            .enterAmount(sendAmount)
            .tapNextButton()
            .enterDestination(destinationAddress)
            .waitForDestinationValue(destinationAddress)
            .waitForAdditionalFieldDisabled()
            .waitForAlreadyIncludedText()
            .waitForNextButtonEnabled()
    }

    func testAddressScreen_XRPAddressEntrySameAsWallet() throws {
        setAllureId(4594)

        let tokenName = "XRP Ledger"
        let sendAmount = "1"
        let destinationAddress = "X7xHWWKb12hgE5MpY13RYbPCNn2Cnq8rnBmytsDjNz5ZQdQ"

        let xrpScenario = ScenarioConfig(
            name: "user_tokens_api",
            initialState: "XRP"
        )

        launchApp(
            tangemApiType: .mock,
            scenarios: [xrpScenario]
        )

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .longPressToken(tokenName)
            .waitForActionButtons()
            .tapSend()

        SendScreen(app)
            .enterAmount(sendAmount)
            .tapNextButton()
            .enterDestination(destinationAddress)
            .waitForDestinationValue(destinationAddress)
            .waitForAddressSameAsWalletText()
            .waitForNextButtonDisabled()
    }

    func testAddressScreen_XRPEnterOwnXAddress() {
        setAllureId(4593)

        let tokenName = "XRP Ledger"
        let sendAmount = "1"
        let destinationAddress = "XVNpatGaPNpPbiAJsQz6ZczZFt97QBbFimbtGZnxBMC7ug9"

        let xrpScenario = ScenarioConfig(
            name: "user_tokens_api",
            initialState: "XRP"
        )

        launchApp(
            tangemApiType: .mock,
            scenarios: [xrpScenario]
        )

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .longPressToken(tokenName)
            .waitForActionButtons()
            .tapSend()

        SendScreen(app)
            .enterAmount(sendAmount)
            .tapNextButton()
            .enterAdditionalField("12345")
            .tapDestinationField()
            .enterDestination(destinationAddress)
            .waitForDestinationValue(destinationAddress)
            .waitForAdditionalFieldIsEmpty()
            .waitForAddressSameAsWalletText()
            .waitForNextButtonEnabled()
    }
}
