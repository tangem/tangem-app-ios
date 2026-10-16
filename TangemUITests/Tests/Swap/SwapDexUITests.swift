//
//  SwapDexUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class SwapDexUITests: BaseTestCase {
    func testDexSwapStatusBlock() {
        setAllureId(9459)

        launchApp(
            tangemApiType: .mock,
            expressApiType: .mock,
            clearStorage: true,
            scenarios: [
                ScenarioConfig(name: "user_tokens_api", initialState: "HotWalletSvS"),
                ScenarioConfig(name: "quotes_api", initialState: "PolygonUSDC"),
                ScenarioConfig(name: "express_api_assets", initialState: "BitcoinExchangeEnabled"),
                ScenarioConfig(name: "ethereum_from_pairs", initialState: "DexProvider"),
                ScenarioConfig(name: "exchange_status_provider", initialState: "OneInchFinished"),
            ]
        )

        importHotWallet()
            .tapToken("POL (ex-MATIC)")
            .waitForNonZeroTotalBalance()
            .tapSwapButton()
            .closeStoriesIfNeeded()
            .validateSwapScreenDisplayed()
            .chooseReceiveToken("Ethereum")
            .enterFromAmount("50")
            .assertNetworkFeeBlockDisplayed()
            .confirmSwap()

        let tokenScreen = SendFinishScreen(app)
            .waitForDisplay()
            .tapCloseButton()
            .waitForPendingExpressTransaction()

        // The swap status shown on the details screen comes from the transaction history list, not /v1/exchange-status.
        wireMockClient.setScenarioStateSync("exchange_history", state: "SwapFinished")
        pullToRefresh()

        let detailsSheet = tokenScreen
            .tapPendingExpressTransaction()
            .waitForDisplay()
            .assertProviderTitle(contains: "1Inch")

        detailsSheet
            .assertHeaderDateDisplayed()
            .assertHeaderTitle(contains: "Swapped")
            .assertLegAmountDisplayed(legId: "from")
            .assertLegAmountDisplayed(legId: "to")
            .assertRateRowDisplayed()

        detailsSheet
            .tapProviderRow()
            .waitForBrowserOpened()
    }

    func testSuccessfulSwapEndToEnd() {
        setAllureId(11523)

        launchApp(
            tangemApiType: .mock,
            expressApiType: .mock,
            clearStorage: true,
            scenarios: [
                ScenarioConfig(name: "user_tokens_api", initialState: "HotWalletSvS"),
                ScenarioConfig(name: "quotes_api", initialState: "PolygonUSDC"),
                ScenarioConfig(name: "express_api_assets", initialState: "BitcoinExchangeEnabled"),
                ScenarioConfig(name: "ethereum_from_pairs", initialState: "DexProvider"),
            ]
        )

        let swapScreen = importHotWallet()
            .tapToken(Constants.fromTokenName)
            .waitForNonZeroTotalBalance()
            .tapSwapButton()
            .closeStoriesIfNeeded()
            .validateSwapScreenDisplayed()

        swapScreen
            .selectFormVariant(Constants.detailedMode)
            .waitFromTokenDisplayed(tokenSymbol: Constants.fromTokenSymbol)
            .assertReceiveTokenNotSelected()
            .assertFromAmountIsZero()
            .assertFromFiatAmountIsZero()
            .assertReceiveAmountIsZero()
            .assertReceiveFiatAmountIsZero()

        swapScreen
            .chooseReceiveToken(Constants.receiveTokenName)
            .waitToTokenDisplayed(tokenSymbol: Constants.receiveTokenSymbol)
            .assertAmountFractionsDisplayed()
            .enterFromAmount(Constants.inputAmount)
            .waitForFromAmountValue(Constants.inputAmount)
            .waitForFromFiatAmountDisplayed()
            .assertReceiveAmountIsNotZero()
            .verifyProviderName(contains: Constants.providerName)
            .assertNetworkFeeBlockDisplayed()
            .confirmSwap()

        SendFinishScreen(app)
            .waitForDisplay()
            .assertHeaderTitle(Constants.swapInProgressTitle)
            .assertTransactionTimeDisplayed()
            .assertSwapSourceAmount(containsLabels: [[Constants.fromTokenSymbol, Constants.inputAmount], [Constants.fiatSign]])
            .assertSwapDestinationAmount(containsLabels: [[Constants.approximateSign, Constants.receiveTokenSymbol], [Constants.fiatSign]])
            .assertSwapProviderLogoDisplayed()
            .assertSwapProvider(containsLabels: [[Constants.providerName], [Constants.providerType], [Constants.rateSign]])
            .assertNetworkFee(containsLabels: [[Constants.marketFeeTitle], [Constants.feeCoinSymbol], [Constants.fiatSign]])
            .assertExploreButtonDisplayed()
            .assertCloseButtonDisplayed()
    }
}

private extension SwapDexUITests {
    enum Constants {
        static let fromTokenName = "POL (ex-MATIC)"
        static let fromTokenSymbol = "POL"
        static let receiveTokenName = "Ethereum"
        static let receiveTokenSymbol = "ETH"
        static let inputAmount = "50"
        static let providerName = "1Inch"
        static let providerType = "DEX"
        static let detailedMode = "Detailed mode"
        static let swapInProgressTitle = "Swap in progress"
        static let marketFeeTitle = "Market"
        static let feeCoinSymbol = "ETH"
        static let fiatSign = "$"
        static let approximateSign = "~"
        static let rateSign = "≈"
    }
}
