//
//  SendConfirmationUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class SendConfirmationUITests: BaseTestCase {
    func testAmountChange_WhenEditingAmountOnSummaryScreen() {
        setAllureId(4003)

        let tokenName = "Ethereum"
        let inputAmount = "1"
        let newInputAmount = "0.9"
        let ethereumAmount = "1.00"
        let fiatAmount = "$2,535.63"
        let newEthereumAmount = "0.90"
        let newFiatAmount = "$2,282.07"
        let destination = "0x24298f15b837E5851925E18439490859e0c1F1ee"

        launchApp(tangemApiType: .mock)

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(tokenName)
            .tapSendButton()
            .waitForDisplay()
            .enterAmount(inputAmount)
            .tapNextButton()
            .enterDestination(destination)
            .tapNextButtonToSummary()
            .validateCryptoAmount(ethereumAmount)
            .validateFiatAmount(fiatAmount)
            .tapAmountField()
            .clearAmount()
            .enterAmount(newInputAmount)
            .tapNextButtonToSummary()
            .validateCryptoAmount(newEthereumAmount)
            .validateFiatAmount(newFiatAmount)
    }

    func testAmountScreen_CurrencyEquivalentSwitchingAndSummaryValidation() {
        setAllureId(552)

        let tokenName = "Ethereum"
        let inputAmount = "1"
        let ethereumAmount = "ETH\u{00A0}1.00"
        let fiatAmount = "$2,535.63"
        let summaryEthereumAmount = "1.00"
        let destination = "0x24298f15b837E5851925E18439490859e0c1F1ee"

        launchApp(tangemApiType: .mock)

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(tokenName)
            .tapSendButton()
            .waitForDisplay()
            .enterAmount(inputAmount)
            .validateCurrencySymbol("ETH")
            .waitForFiatAmount(fiatAmount)
            .toggleCurrency()
            .validateCurrencySymbol("$")
            .waitForCryptoAmount(ethereumAmount)
            .toggleCurrency()
            .validateCurrencySymbol("ETH")
            .waitForFiatAmount(fiatAmount)
            .tapNextButton()
            .enterDestination(destination)
            .tapNextButtonToSummary()
            .validateCryptoAmount(summaryEthereumAmount)
            .validateFiatAmount(fiatAmount)
    }

    func testNetworkFeeLessThanSignDisplayed_WhenFeeCannotBeAccuratelyCalculated() {
        setAllureId(553)

        let token = "Polygon"
        let inputAmount = "1"
        let currentFeeAmount = "< $0.01"
        let destination = "0x24298f15b837E5851925E18439490859e0c1F1ee"

        launchApp(tangemApiType: .mock)

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(token)
            .tapSendButton()
            .waitForDisplay()
            .enterAmount(inputAmount)
            .tapNextButton()
            .enterDestination(destination)
            .tapNextButton()
            .validateNetworkFee(currentFeeAmount)
    }

    func testNetworkFeeLessThanSignDisplayed_ForPOL_WhenFeeIsUnknown() {
        setAllureId(4565)

        let tokenName = "POL (ex-MATIC)"
        let inputAmount = "1"
        let destination = "0x24298f15b837E5851925E18439490859e0c1F1ee"
        let currentFeeAmount = "< $0.01"

        let ethEstimateGasScenario = ScenarioConfig(
            name: "eth_estimate_gas",
            initialState: "UnknownFee"
        )

        launchApp(
            tangemApiType: .mock,
            scenarios: [ethEstimateGasScenario]
        )

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(tokenName)
            .tapSendButton()
            .waitForDisplay()
            .enterAmount(inputAmount)
            .tapNextButton()
            .enterDestination(destination)
            .tapNextButton()
            .validateNetworkFee(currentFeeAmount)
    }

    func testNetworkFeeUnreachableAndRefresh_ForPolkadot() {
        setAllureId(554)

        let tokenName = "Polkadot"
        let tokenAmount = "0.1"
        let destinationAddress = "143TfgFYAFfM86LRzt4UcFNU3KosxCndBCVz2U5HCxpLidKZ"
        let currentFeeAmount = "$0.05"

        let tokensScenario = ScenarioConfig(name: "user_tokens_api", initialState: "Polkadot")
        let quotesScenario = ScenarioConfig(name: "quotes_api", initialState: "Polkadot")
        let gasUnreachableScenario = ScenarioConfig(name: "polkadot_query_info", initialState: "Unreachable")

        launchApp(
            tangemApiType: .mock,
            clearStorage: true,
            scenarios: [tokensScenario, quotesScenario, gasUnreachableScenario]
        )

        let sendScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(tokenName)
            .tapSendButton()
            .waitForDisplay()
            .enterAmount(tokenAmount)
            .tapNextButton()
            .enterDestination(destinationAddress)
            .tapNextButton()
            .waitForNetworkFeeUnreachableBanner()
            .waitForSendButtonDisabled()

        setupWireMockScenarios([.init(name: "polkadot_query_info", initialState: "Started")])

        sendScreen
            .tapNotificationRefresh()
            .waitForNetworkFeeUnreachableBannerNotExists()
            .validateNetworkFee(currentFeeAmount)
            .waitForSendButtonEnabled()
    }
}
