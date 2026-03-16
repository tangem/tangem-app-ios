//
//  SendViaSwapUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class SendViaSwapUITests: BaseTestCase {
    func testSendViaSwapFlowWithTokenSearchAndDataChanges() {
        setAllureId(3968)

        let bitcoinBalanceScenario = ScenarioConfig(
            name: "bitcoin_utxo",
            initialState: "Balance"
        )

        let assetsScenario = ScenarioConfig(
            name: "express_api_assets",
            initialState: "BitcoinExchangeEnabled"
        )

        launchApp(
            tangemApiType: .mock,
            expressApiType: .mock,
            scenarios: [bitcoinBalanceScenario, assetsScenario]
        )

        // Open Bitcoin token and navigate to Send screen
        let sendScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(Constants.bitcoinTokenName)
            .tapSendButton()
            .waitForDisplay()
            .waitForConvertButton()
            .tapConvertButton()

        // Search for Ethereum token and select it with network
        sendScreen
            .enterTokenSearch("Ethereum")
            .waitForReceiveToken(name: Constants.ethereumTokenName)
            .tapReceiveToken(name: Constants.ethereumTokenName)
            .tapReceiveNetworkOption(name: "Ethereum")

        // Fill amount and destination, proceed to Summary
        let summaryScreen = sendScreen
            .enterAmount(Constants.sendAmount)
            .tapNextButton()
            .enterDestination(Constants.ethereumAddress)
            .tapNextButtonToSummary()
            .waitForDisplay(checkValidatorBlock: false)

        // Open provider selector, verify all providers are CEX with Best Rate badge
        let providerSelector = summaryScreen
            .tapProviderBlock()
            .waitForDisplay()
            .assertAllProvidersCEX()
            .assertBestRateBadgeExists()

        // Select a non-best provider, verify Best Rate badge is removed
        let (selectedProviderName, _) = providerSelector.selectNonBestProvider()

        summaryScreen
            .assertProviderName(selectedProviderName)
            .assertBestRateBadgeNotOnProvider()

        // Change network fee to Fast, verify fee value changed
        let feeBefore = summaryScreen.getNetworkFeeValue()

        summaryScreen
            .tapFeeBlock()
            .waitForSwapFeeOptions(cryptoSymbol: "BTC", fiatSymbol: "$")
            .selectFast()
            .assertNetworkFeeChanged(from: feeBefore)

        // Return to amount step, update it and proceed back to Summary
        summaryScreen
            .tapAmountField()
            .waitForDisplay()
            .clearAmount()
            .enterAmount(Constants.updatedAmount)
            .tapNextButtonToSummary()
            .waitForDisplay(checkValidatorBlock: false)
    }

    func testSendViaSwapCancelAndReturnFlow() {
        setAllureId(3969)

        let bitcoinBalanceScenario = ScenarioConfig(
            name: "bitcoin_utxo",
            initialState: "Balance"
        )

        let assetsScenario = ScenarioConfig(
            name: "express_api_assets",
            initialState: "BitcoinExchangeEnabled"
        )

        launchApp(
            tangemApiType: .mock,
            expressApiType: .mock,
            scenarios: [bitcoinBalanceScenario, assetsScenario]
        )

        // Open Bitcoin token and navigate to Send screen
        let sendScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(Constants.bitcoinTokenName)
            .tapSendButton()
            .waitForDisplay()
            .waitForConvertButton()

        // Select Ethereum, enter amount, then cancel conversion — verify Convert button reappears
        sendScreen
            .tapConvertButton()
            .tapReceiveToken(name: Constants.ethereumTokenName)
            .tapReceiveNetworkOption(name: "Ethereum")
            .enterAmount(Constants.sendAmount)
            .tapRemoveConvertButton()
            .waitForConvertButton()

        // Re-enter conversion and select Solana
        sendScreen
            .tapConvertButton()
            .tapReceiveToken(name: Constants.solanaTokenName)
            .tapReceiveNetworkOption(name: "Solana")

        // Fill amount and Solana address, proceed to Summary
        sendScreen
            .clearAmount()
            .enterAmount(Constants.sendAmount)
            .tapNextButton()
            .enterDestination(Constants.solanaAddress)
            .tapNextButtonToSummary()
            .waitForDisplay(checkValidatorBlock: false)

        // Attempt to change receive token to Ethereum — triggers "Changing token" alert
        sendScreen
            .tapReceiveTokenBlock()
            .tapReceiveTokenBlock()
            .tapReceiveToken(name: Constants.ethereumTokenName)
            .tapReceiveNetworkOption(name: "Ethereum")

        // Cancel the alert — verify amount and destination are preserved
        sendScreen
            .waitForChangeTokenAlert()
            .tapChangeTokenAlertCancel()
            .tapChooseTokenCloseButton()

        sendScreen
            .waitForAmountValue(Constants.sendAmount)
            .tapNextButton()
            .waitForDestinationValue(Constants.solanaAddress)

        // Proceed to Summary again
        sendScreen
            .tapNextButtonToSummary()
            .waitForDisplay(checkValidatorBlock: false)

        // Change receive token to Ethereum again and confirm — data should reset
        sendScreen
            .tapReceiveTokenBlock()
            .tapReceiveTokenBlock()
            .tapReceiveToken(name: Constants.ethereumTokenName)
            .tapReceiveNetworkOption(name: "Ethereum")
            .waitForChangeTokenAlert()
            .tapChangeTokenAlertContinue()

        // Verify screen reset: re-enter amount, destination field should be empty
        sendScreen
            .waitForDisplay()
            .enterAmount(Constants.sendAmount)
            .tapNextButton()
            .validateDestinationIsEmpty()
    }

    func testSendConvertToUnsupportedTokenShowsError() {
        setAllureId(3970)

        let bitcoinBalanceScenario = ScenarioConfig(
            name: "bitcoin_utxo",
            initialState: "Balance"
        )

        let assetsScenario = ScenarioConfig(
            name: "express_api_assets",
            initialState: "BitcoinExchangeEnabled"
        )

        launchApp(
            tangemApiType: .mock,
            expressApiType: .mock,
            scenarios: [bitcoinBalanceScenario, assetsScenario]
        )

        // Open Bitcoin token and navigate to Send screen
        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(Constants.bitcoinTokenName)
            .tapSendButton()
            .waitForDisplay()
            .waitForConvertButton()
            .tapConvertButton()
            // Select unsupported token (Stellar) — verify error is shown, then dismiss and go back
            .tapReceiveToken(name: Constants.stellarTokenName)
            .waitForNetworkSelectorError(tokenName: Constants.stellarTokenName)
            .tapNetworkSelectorGotItButton()
            .tapChooseTokenCloseButton()
            .tapCloseButton()
            .goBackToMain()
    }
}

private extension SendViaSwapUITests {
    enum Constants {
        static let bitcoinTokenName = "Bitcoin"
        static let solanaTokenName = "Solana"
        static let stellarTokenName = "Stellar"
        static let ethereumTokenName = "Ethereum"
        static let ethereumAddress = "0x24298f15b837E5851925E18439490859e0c1F1ee"
        static let solanaAddress = "5fcy9woa8Di1QHcce65CsV3XKrxdB2pD4HJx5xx82ipM"
        static let sendAmount = "0.001"
        static let updatedAmount = "0.002"
    }
}
