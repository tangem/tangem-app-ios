//
//  SwapCommonUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class SwapCommonUITests: BaseTestCase {
    private let token = "Polygon"
    private let fromTokenSymbol = "POL"
    private let receiveTokenSymbol = "ETH"
    private let alternativeToken = "Bitcoin"

    func testCheckSwapUI() {
        setAllureId(575)

        launchApp(tangemApiType: .mock, expressApiType: .mock)

        let swapScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(token)
            .tapSwapButton()
            .closeStoriesIfNeeded()
            .validateSwapScreenDisplayed()

        // The source token's chevron/selector is present even from this entry, contradicting the ticket's "can't be changed" claim.
        swapScreen
            .waitFromTokenDisplayed(tokenSymbol: fromTokenSymbol)
            .waitForFromBalanceDisplayed()
            .waitForFromFiatAmountDisplayed()

        swapScreen
            .tapToTokenSelector()
            .selectToken(alternativeToken)
            .validateSwapScreenDisplayed()

        swapScreen
            .enterFromAmount("1")
            .waitForFromAmountValue("1")
            .validateReceivedAmount()
            .clearFromAmount()
            .waitForConfirmButtonDisabled()

        swapScreen
            .waitForSwapTokensButtonDisplayed()
    }

    func testSwapButtonAvailability() {
        setAllureId(573)

        launchApp(
            tangemApiType: .mock,
            expressApiType: .mock,
            scenarios: [
                ScenarioConfig(name: "user_tokens_api", initialState: "CustomTokenAndJesusAdded"),
            ]
        )

        let mainScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)

        mainScreen
            .tapToken("Polygon")
            .waitForSwapButtonEnabled()
            .goBackToMain()

        // Bitcoin has exchangeAvailable=false, but button is enabled — verify swap is unavailable on the swap screen
        mainScreen
            .tapToken("Bitcoin")
            .waitForSwapButtonEnabled()
            .tapSwapButton()
            .closeStoriesIfNeeded()
            .waitForConfirmButtonDisabled()
            .tapCloseButton()
            .goBackToMain()

        mainScreen
            .tapToken("Salam")
            .tapUnavailableSwapButton()

        waitAndDismissErrorAlert(actionName: "Swap", expectedMessage: "custom tokens")
    }

    func testSwapButtonNotDisplayedOnSingleCurrencyCards() {
        setAllureId(574)

        launchApp(tangemApiType: .mock)

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .xrpNote)
            .validate(cardType: .xrpNote)
            .waitForSwapButtonNotAvailable()
    }

    func testSwapTokensSwitch() {
        setAllureId(5162)

        launchApp(
            tangemApiType: .mock,
            expressApiType: .mock,
            scenarios: [
                ScenarioConfig(name: "polygon_pos_to_pairs", initialState: "DexProvider"),
                ScenarioConfig(name: "exchange_quote_ethereum_polygon", initialState: "Native"),
            ]
        )

        let swapScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(token)
            .tapSwapButton()
            .closeStoriesIfNeeded()
            .validateSwapScreenDisplayed()

        swapScreen
            .waitFromTokenDisplayed(tokenSymbol: fromTokenSymbol)
            .chooseReceiveToken("Ethereum")
            .waitToTokenDisplayed(tokenSymbol: receiveTokenSymbol)

        swapScreen
            .enterFromAmount("1")
            .validateReceivedAmount()
            .assertFeeCurrencySymbol(fromTokenSymbol)
            .waitForSwapTokensButtonEnabled()

        let initialReceiveAmount = swapScreen.captureReceiveAmount()

        swapScreen
            .tapSwapTokensButton()

        swapScreen
            .waitFromTokenDisplayed(tokenSymbol: receiveTokenSymbol)
            .waitToTokenDisplayed(tokenSymbol: fromTokenSymbol)
            .waitForSwapTokensButtonEnabled()

        swapScreen
            .enterFromAmount("0.1")
            .validateReceivedAmount()
            .assertReceiveAmount(notEquals: initialReceiveAmount)
            .assertFeeCurrencySymbol(receiveTokenSymbol)
    }

    func testPredefinedPercentButtons() {
        setAllureId(9458)

        launchApp(
            tangemApiType: .mock,
            expressApiType: .mock,
            scenarios: [
                ScenarioConfig(name: "polygon_pos_to_pairs", initialState: "DexProvider"),
                ScenarioConfig(name: "polygon_pos_from_pairs", initialState: "DexProvider"),
            ]
        )

        let swapScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken("Ethereum")
            .waitForNonZeroTotalBalance()
            .tapSwapButton()
            .closeStoriesIfNeeded()
            .validateSwapScreenDisplayed()
            .chooseReceiveToken("Polygon")

        swapScreen
            .tapAmountFraction("25")
            .waitForFromAmountValue("0.25")

        swapScreen
            .tapAmountFraction("50")
            .waitForFromAmountValue("0.5")

        swapScreen
            .tapAmountFraction("75")
            .waitForFromAmountValue("0.75")

        swapScreen
            .tapAmountFraction("max")
            .waitForFromAmountValue("1")
    }

    func testProviderTypeFilter() {
        setAllureId(9456)

        // Only the Ethereum-network POL pair has a DEX provider (1inch) alongside the CEX ones; the Polygon-network pair is CEX-only.
        launchApp(tangemApiType: .mock, expressApiType: .mock)

        let swapScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken("Ethereum")
            .waitForNonZeroTotalBalance()
            .tapSwapButton()
            .closeStoriesIfNeeded()
            .validateSwapScreenDisplayed()
            .chooseReceiveToken("POL (ex-MATIC)")

        swapScreen.enterFromAmount("0.1")

        let providerSelector = swapScreen
            .tapProviderBlock()
            .waitForDisplay()

        providerSelector
            .assertFilterDisplayed("all")
            .assertFilterDisplayed("cex")
            .assertFilterDisplayed("dex")
            .assertProvidersIncludeBothTypes()

        providerSelector
            .selectFilter("cex")
            .assertAllProvidersCEX()

        providerSelector
            .selectFilter("dex")
            .assertAllProvidersDEX()
            .selectProviderReturningToSwap(name: "1Inch")
            .verifyProviderName(contains: "1Inch")
    }

    func testEnterSendAmountInTokenAndFiat() {
        setAllureId(11517)

        launchApp(
            tangemApiType: .mock,
            expressApiType: .mock,
            scenarios: [
                ScenarioConfig(name: "exchange_quote_polygon", initialState: "NonProportionalRate"),
            ]
        )

        let swapScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(token)
            .waitForNonZeroTotalBalance()
            .tapSwapButton()
            .closeStoriesIfNeeded()
            .validateSwapScreenDisplayed()
            .selectFormVariant(Constants.detailedMode)
            .chooseReceiveToken(Constants.ethereumTokenName)
            .enterFromAmount(Constants.tokenAmount)

        let fiatEquivalent = swapScreen.captureFromFiatEquivalent()
        let rateForTokenAmount = swapScreen.captureProviderRate()
        let feeForTokenAmount = swapScreen.captureLoadedFeeAmount()
        let receiveAmountForTokenAmount = swapScreen
            .assertReceiveAmountIsNotZero()
            .captureReceiveAmount()

        let tokenEquivalent = swapScreen
            .tapCurrencyToggle()
            .assertFromAmountContainsDigits(of: fiatEquivalent)
            .assertReceiveAmount(equals: receiveAmountForTokenAmount)
            .captureFromTokenEquivalent()

        swapScreen
            .enterFromAmount(Constants.fiatAmount)
            .assertFromAlternativeAmountInToken(notEquals: tokenEquivalent)
            .assertReceiveAmount(notEquals: receiveAmountForTokenAmount)
            .assertProviderRate(notEquals: rateForTokenAmount)
            .assertLoadedFeeAmount(notEquals: feeForTokenAmount)
    }

    func testTurnOnDetailedMode() {
        setAllureId(9984)

        launchApp(tangemApiType: .mock, expressApiType: .mock)

        let swapScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(Constants.ethereumTokenName)
            .waitForNonZeroTotalBalance()
            .tapSwapButton()
            .closeStoriesIfNeeded()
            .validateSwapScreenDisplayed()
            .chooseReceiveToken(Constants.polTokenName)
            .enterFromAmount(Constants.ethereumAmount)

        swapScreen
            .selectFormVariant(Constants.simpleMode)
            .assertSimpleModeDisplayed()

        swapScreen
            .openFormVariantMenu()
            .assertFormVariantMenuItems(selected: Constants.simpleMode, notSelected: Constants.detailedMode)
            .tapFormVariantMenuItem(Constants.detailedMode)
            .assertFormVariantMenuClosed(Constants.simpleMode)
            .assertDetailedModeDisplayed(providerName: Constants.bestProviderName)
    }
}

private extension SwapCommonUITests {
    enum Constants {
        static let ethereumTokenName = "Ethereum"
        static let polTokenName = "POL (ex-MATIC)"
        static let tokenAmount = "1"
        static let fiatAmount = "5"
        static let ethereumAmount = "0.1"
        static let simpleMode = "Simple mode"
        static let detailedMode = "Detailed mode"
        static let bestProviderName = "1Inch"
    }
}
