//
//  SendAddressUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class SendAddressUITests: BaseTestCase {
    func testDestinationCodeField_CheckFieldValidation() {
        setAllureId(4004)

        let tokenName = "XRP Ledger"
        let sendAmount = "1"
        let correctMemo = "123"
        let invalidMemo = "hz"
        let destinationAddress = "rN7n7otQDd6FczFgLdSqtcsAUxDkw6fzRH"

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
            .pasteAdditionalField(correctMemo)
            .waitForAdditionalFieldValue(correctMemo)
            .waitForInvalidMemoBannerNotExists()
            .clearAdditionalField()
            .enterAdditionalField(invalidMemo)
            .waitForInvalidMemoBanner()
            .clearAdditionalField()
            .waitForInvalidMemoBannerNotExists()
            .pasteAdditionalField(invalidMemo)
            .waitForInvalidMemoBanner()
            .clearAdditionalField()
            .waitForAdditionalFieldIsEmpty()
    }

    func testAddressScreen_WalletHistoryInteraction() {
        setAllureId(4005)

        let tokenName = "Dogecoin"
        let sendAmount = "1"

        let dogecoinScenario = ScenarioConfig(
            name: "user_tokens_api",
            initialState: tokenName
        )

        let dogecoinQuotesScenario = ScenarioConfig(
            name: "quotes_api",
            initialState: tokenName
        )

        let txHistoryScenario = ScenarioConfig(
            name: "dogecoin_tx_history",
            initialState: "OutgoingTransaction"
        )

        launchApp(
            tangemApiType: .mock,
            scenarios: [dogecoinScenario, dogecoinQuotesScenario, txHistoryScenario]
        )

        let sendScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .longPressToken(tokenName)
            .waitForActionButtons()
            .tapSend()
            .waitForDisplay()
            .enterAmount(sendAmount)
            .tapNextButton()

        sendScreen
            .waitForWalletHistoryDisplayed()

        let selectedAddress = sendScreen.selectFirstAvailableHistoryCell()

        sendScreen
            .waitForDestinationValue(selectedAddress)
            .tapBackButton()
            .waitForDestinationValue(selectedAddress)
            .waitForWalletHistoryNotDisplayed()
            .waitForNextButtonEnabled()
            .clearDestination()
            .waitForNextButtonDisabled()
            .validateDestinationIsEmpty()
            .waitForWalletHistoryDisplayed()
    }

    func testAddressScreen_RecentBlockNotDisplayedWhenTransactionHistoryError() {
        setAllureId(4598)

        let tokenName = "Dogecoin"
        let sendAmount = "1"

        let dogecoinScenario = ScenarioConfig(
            name: "user_tokens_api",
            initialState: tokenName
        )

        let dogecoinQuotesScenario = ScenarioConfig(
            name: "quotes_api",
            initialState: tokenName
        )

        let txHistoryScenario = ScenarioConfig(
            name: "dogecoin_tx_history",
            initialState: "Error"
        )

        launchApp(
            tangemApiType: .mock,
            scenarios: [dogecoinScenario, dogecoinQuotesScenario, txHistoryScenario]
        )

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .longPressToken(tokenName)
            .waitForActionButtons()
            .tapSend()
            .waitForDisplay()
            .enterAmount(sendAmount)
            .tapNextButton()
            .waitForTransactionHistoryNotDisplayed()
    }

    func testAddressScreen_RecentBlockNotDisplayedWhenTransactionHistoryNotSupported() {
        setAllureId(4597)

        let tokenName = "Polkadot"
        let sendAmount = "1"

        let polkadotScenario = ScenarioConfig(
            name: "user_tokens_api",
            initialState: tokenName
        )

        let polkadotQuotesScenario = ScenarioConfig(
            name: "quotes_api",
            initialState: tokenName
        )

        launchApp(
            tangemApiType: .mock,
            scenarios: [polkadotScenario, polkadotQuotesScenario]
        )

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .longPressToken(tokenName)
            .tapSend()
            .waitForDisplay()
            .enterAmount(sendAmount)
            .tapNextButton()
            .waitForTransactionHistoryNotDisplayed()
    }

    func testAddressScreen_RecentBlockDisplayedWithMoreThan10Transactions() {
        setAllureId(4572)

        let tokenName = "Dogecoin"
        let sendAmount = "1"
        let txHistoryScenarioState = "11OutgoingTransactions"
        let scenarioState = "Dogecoin"

        let dogecoinScenario = ScenarioConfig(
            name: "user_tokens_api",
            initialState: scenarioState
        )

        let dogecoinQuotesScenario = ScenarioConfig(
            name: "quotes_api",
            initialState: scenarioState
        )

        let txHistoryScenario = ScenarioConfig(
            name: "dogecoin_tx_history",
            initialState: txHistoryScenarioState
        )

        launchApp(
            tangemApiType: .mock,
            clearStorage: true,
            scenarios: [dogecoinScenario, dogecoinQuotesScenario, txHistoryScenario]
        )

        let sendScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .longPressToken(tokenName)
            .waitForActionButtons()
            .tapSend()
            .waitForDisplay()
            .enterAmount(sendAmount)
            .tapNextButton()
            .waitForRecentHeaderDisplayed()
            .waitForWalletHistoryDisplayed()
            .validateTransactionHistoryCount(maxCount: 10)

        let transactionCount = sendScreen.getTransactionHistoryCount()
        let cellsToCheck = min(3, transactionCount)
        for index in 0 ..< cellsToCheck {
            sendScreen.waitForTransactionCellHasElements(at: index)
        }

        let selectedAddress = sendScreen.getAddressFromTransactionCell(at: 0)

        sendScreen
            .selectTransactionCell(at: 0)
            .waitForDestinationValue(selectedAddress)
    }

    func testAddressScreen_RecentBlockNotDisplayedWhenNoOutgoingSendTransactions() {
        setAllureId(4596)

        let tokenName = "Dogecoin"
        let sendAmount = "1"

        let dogecoinScenario = ScenarioConfig(
            name: "user_tokens_api",
            initialState: tokenName
        )

        let dogecoinQuotesScenario = ScenarioConfig(
            name: "quotes_api",
            initialState: tokenName
        )

        let txHistoryScenario = ScenarioConfig(
            name: "dogecoin_tx_history",
            initialState: "Empty"
        )

        launchApp(
            tangemApiType: .mock,
            scenarios: [dogecoinScenario, dogecoinQuotesScenario, txHistoryScenario]
        )

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .longPressToken(tokenName)
            .tapSend()
            .waitForDisplay()
            .enterAmount(sendAmount)
            .tapNextButton()
            .waitForTransactionHistoryNotDisplayed()
    }

    func testAddressScreen_RecentBlockDisplayedWithTwoOutgoingTransactionsToSameAddress() {
        setAllureId(4676)

        let tokenName = "Dogecoin"
        let sendAmount = "1"
        let txHistoryScenarioState = "2OutgoingTransactions"

        let dogecoinScenario = ScenarioConfig(
            name: "user_tokens_api",
            initialState: tokenName
        )

        let dogecoinQuotesScenario = ScenarioConfig(
            name: "quotes_api",
            initialState: tokenName
        )

        let txHistoryScenario = ScenarioConfig(
            name: "dogecoin_tx_history",
            initialState: txHistoryScenarioState
        )

        launchApp(
            tangemApiType: .mock,
            scenarios: [dogecoinScenario, dogecoinQuotesScenario, txHistoryScenario]
        )

        let sendScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .longPressToken(tokenName)
            .tapSend()
            .waitForDisplay()
            .enterAmount(sendAmount)
            .tapNextButton()
            .waitForRecentHeaderDisplayed()
            .waitForWalletHistoryDisplayed()

        let transactionCount = sendScreen.getTransactionHistoryCount()
        XCTAssertEqual(
            transactionCount, 2,
            "Transaction history should display exactly 2 transactions"
        )

        let firstAddress = sendScreen.getAddressFromTransactionCell(at: 0)
        let secondAddress = sendScreen.getAddressFromTransactionCell(at: 1)

        XCTAssertEqual(
            firstAddress, secondAddress,
            "Both transactions should have the same address"
        )

        for index in 0 ..< 2 {
            sendScreen.waitForTransactionCellHasElements(at: index)
        }

        let selectedAddress = sendScreen.getAddressFromTransactionCell(at: 0)
        sendScreen
            .selectTransactionCell(at: 0)
            .waitForDestinationValue(selectedAddress)
    }

    func testAddressScreen_AddressUIElementsDisplayed() {
        setAllureId(4567)

        let tokenName = "Dogecoin"
        let sendAmount = "1"

        let dogecoinScenario = ScenarioConfig(
            name: "user_tokens_api",
            initialState: tokenName
        )

        let dogecoinQuotesScenario = ScenarioConfig(
            name: "quotes_api",
            initialState: tokenName
        )

        launchApp(
            tangemApiType: .mock,
            scenarios: [dogecoinScenario, dogecoinQuotesScenario]
        )

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .longPressToken(tokenName)
            .waitForActionButtons()
            .tapSend()
            .waitForDisplay()
            .enterAmount(sendAmount)
            .tapNextButton()
            .waitForAddressScreenElements()
    }

    func testAddressScreen_PasteButtonValidation() {
        setAllureId(4543)

        let tokenName = "Dogecoin"
        let sendAmount = "1"
        let validAddress = "DJQR3bdhBKcFGMHX2BkMCkrMFApNWNzr6V"
        let invalidAddress = "invalid_address_123"

        let dogecoinScenario = ScenarioConfig(
            name: "user_tokens_api",
            initialState: tokenName
        )

        let dogecoinQuotesScenario = ScenarioConfig(
            name: "quotes_api",
            initialState: tokenName
        )

        launchApp(
            tangemApiType: .mock,
            scenarios: [dogecoinScenario, dogecoinQuotesScenario]
        )

        let sendScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .longPressToken(tokenName)
            .waitForActionButtons()
            .tapSend()
            .waitForDisplay()
            .enterAmount(sendAmount)
            .tapNextButton()

        sendScreen
            .pasteDestination(validAddress)
            .waitForDestinationValue(validAddress)
            .waitForNextButtonEnabled()
            .waitForInvalidAddressErrorNotDisplayed()

        sendScreen
            .clearDestination()
            .pasteDestination(invalidAddress)
            .waitForDestinationValue(invalidAddress)
            .waitForInvalidAddressText()
            .waitForNextButtonDisabled()

        sendScreen
            .clearDestination()
            .validateDestinationIsEmpty()
            .waitForInvalidAddressErrorNotDisplayed()
    }

    func testAddressScreen_EnsAddressValidation() {
        setAllureId(4009)

        let tokenName = "Ethereum"
        let sendAmount = "1"
        let validEnsAddress = "louded.eth"
        let invalidEnsAddress = "invalid.eth"

        let ethCallValidScenario = ScenarioConfig(
            name: "eth_call_api",
            initialState: "EnsName"
        )

        let ethCallInvalidScenario = ScenarioConfig(
            name: "eth_call_api",
            initialState: "Started"
        )

        launchApp(
            tangemApiType: .mock,
            scenarios: [ethCallValidScenario]
        )

        let sendScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .longPressToken(tokenName)
            .waitForActionButtons()
            .tapSend()
            .waitForDisplay()
            .enterAmount(sendAmount)
            .tapNextButton()

        sendScreen
            .enterDestination(validEnsAddress)
            .waitForResolvedAddressDisplayed()
            .waitForNextButtonEnabled()

        setupWireMockScenarios([ethCallInvalidScenario])

        sendScreen
            .clearDestination()
            .enterDestination(invalidEnsAddress)
            .waitForInvalidAddressText()
            .waitForNextButtonDisabled()
    }
}
