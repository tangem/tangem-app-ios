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
    func testFullSuccessfulSendViaSwapFlow() {
        setAllureId(3967)

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
            clearStorage: true,
            scenarios: [bitcoinBalanceScenario, assetsScenario]
        )

        // Import hot wallet via seed phrase
        let mainScreen = CreateWalletSelectorScreen(app)
            .skipStories()
            .startWithMobileWallet()
            .tapImportButton()
            .enterSeedPhrase(TestSeedPhrases.hotWallet)
            .tapImportButton()
            .tapContinue()
            .skipAccessCode()
            .tapFinish()

        // Navigate to Bitcoin token and open Send screen
        let sendScreen = mainScreen
            .tapToken(Constants.bitcoinTokenName)
            .waitForActionButtons()
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
            .enterReceiveAmount(Constants.sendAmount)
            .tapNextButton()
            .enterDestination(Constants.ethereumAddress)
            .tapNextButtonToSummary()
            .waitForDisplay(checkValidatorBlock: false)
            .assertBestRateBadgeOnProvider()

        // Tap Send and verify Finish screen
        let finishScreen = summaryScreen
            .tapSendButton()
            .waitForDisplay()

        // Tap Explore, verify browser opens, then dismiss
        finishScreen
            .tapExploreButton()
            .waitForBrowserOpened()
            .dismissBrowser()

        // Close finish screen and verify pending express transaction on Token screen
        finishScreen
            .tapCloseButton()
            .waitForPendingExpressTransaction()
    }

    /// [REDACTED_INFO] Send-via-Swap: network fee tier change (Market↔Fast) is not applied on Summary
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
            clearStorage: true,
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
            .enterReceiveAmount(Constants.sendAmount)
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
            .waitForNetworkFeeLoaded(fiatSymbol: "$")

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
            .clearReceiveAmount()
            .enterReceiveAmount(Constants.updatedAmount)
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
            clearStorage: true,
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
            .enterReceiveAmount(Constants.sendAmount)
            .tapRemoveConvertButton()
            .waitForConvertButton()

        // Re-enter conversion and select Solana
        sendScreen
            .tapConvertButton()
            .tapReceiveToken(name: Constants.solanaTokenName)
            .tapReceiveNetworkOption(name: "Solana")

        // Fill amount and Solana address, proceed to Summary
        sendScreen
            .clearReceiveAmount()
            .enterReceiveAmount(Constants.sendAmount)
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
            .waitForReceiveAmountValue(Constants.sendAmount)
            .tapNextButton()
            .waitForDestinationValue(Constants.solanaAddress)
    }

    func testSendSameTokenInDifferentNetwork() {
        setAllureId(4017)

        let userTokensScenario = ScenarioConfig(
            name: "user_tokens_api",
            initialState: "USDT"
        )

        let ethCallScenario = ScenarioConfig(
            name: "eth_call_api",
            initialState: "Started"
        )

        let ethNetworkBalanceScenario = ScenarioConfig(
            name: "eth_network_balance",
            initialState: "Started"
        )

        launchApp(
            tangemApiType: .mock,
            expressApiType: .mock,
            clearStorage: true,
            scenarios: [userTokensScenario, ethCallScenario, ethNetworkBalanceScenario]
        )

        // Import hot wallet via seed phrase
        let mainScreen = CreateWalletSelectorScreen(app)
            .skipStories()
            .startWithMobileWallet()
            .tapImportButton()
            .enterSeedPhrase(TestSeedPhrases.hotWallet)
            .tapImportButton()
            .tapContinue()
            .skipAccessCode()
            .tapFinish()

        // Navigate to Tether token and open Send screen
        let sendScreen = mainScreen
            .tapToken(Constants.tetherTokenName)
            .waitForActionButtons()
            .tapSendButton()
            .waitForDisplay()
            .waitForConvertButton()
            .tapConvertButton()

        // Select Tether on Polygon network (same token, different network)
        sendScreen
            .tapReceiveToken(name: Constants.tetherTokenName)
            .tapReceiveNetworkOption(name: "Polygon")

        // Fill amount and destination, proceed to Summary
        let summaryScreen = sendScreen
            .enterReceiveAmount(Constants.sendAmount)
            .tapNextButton()
            .enterDestination(Constants.polygonAddress)
            .tapNextButtonToSummary()
            .waitForDisplay(checkValidatorBlock: false)

        // Tap Send and verify Finish screen
        let finishScreen = summaryScreen
            .tapSendButton()
            .waitForDisplay()

        // Close finish screen and verify pending express transaction on Token screen
        finishScreen
            .tapCloseButton()
            .waitForPendingExpressTransaction()
    }

    func testSendViaSwapXRPToEthereum() {
        setAllureId(4545)

        let xrpScenario = ScenarioConfig(
            name: "user_tokens_api",
            initialState: "XRP"
        )

        launchApp(
            tangemApiType: .mock,
            expressApiType: .mock,
            clearStorage: true,
            scenarios: [xrpScenario]
        )

        // Import hot wallet via seed phrase
        let mainScreen = CreateWalletSelectorScreen(app)
            .skipStories()
            .startWithMobileWallet()
            .tapImportButton()
            .enterSeedPhrase(TestSeedPhrases.hotWallet)
            .tapImportButton()
            .tapContinue()
            .skipAccessCode()
            .tapFinish()

        // Navigate to XRP Ledger token and open Send screen
        let sendScreen = mainScreen
            .tapToken(Constants.xrpTokenName)
            .waitForActionButtons()
            .tapSendButton()
            .waitForDisplay()
            .waitForConvertButton()

        // Select Ethereum as receive token
        sendScreen
            .tapConvertButton()
            .enterTokenSearch("Ethereum")
            .waitForReceiveToken(name: Constants.ethereumTokenName)
            .tapReceiveToken(name: Constants.ethereumTokenName)
            .tapReceiveNetworkOption(name: "Ethereum")

        // Fill amount and destination, proceed to Summary
        let summaryScreen = sendScreen
            .enterReceiveAmount(Constants.sendAmount)
            .tapNextButton()
            .enterDestination(Constants.ethereumAddress)
            .tapNextButtonToSummary()
            .waitForDisplay(checkValidatorBlock: false)

        // Tap Send and verify Finish screen
        let finishScreen = summaryScreen
            .tapSendButton()
            .waitForDisplay()

        // Close finish screen and verify pending express transaction on Token screen
        finishScreen
            .tapCloseButton()
            .waitForPendingExpressTransaction()
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
            clearStorage: true,
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
        static let xrpTokenName = "XRP Ledger"
        static let solanaTokenName = "Solana"
        static let stellarTokenName = "Stellar"
        static let tetherTokenName = "Tether"
        static let ethereumTokenName = "Ethereum"
        static let ethereumAddress = "0x24298f15b837E5851925E18439490859e0c1F1ee"
        static let polygonAddress = "0x742d35cc6634c0532925a3b844bc9e7595f2bd18"
        static let solanaAddress = "5fcy9woa8Di1QHcce65CsV3XKrxdB2pD4HJx5xx82ipM"
        static let sendAmount = "0.001"
        static let updatedAmount = "0.002"
    }
}
