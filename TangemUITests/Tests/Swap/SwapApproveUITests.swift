//
//  SwapApproveUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class SwapApproveUITests: BaseTestCase {
    private lazy var transactionJournal = EthereumTransactionJournal(wireMockClient: wireMockClient)

    func testApproveSettingsDisplayedForDexProvider() {
        setAllureId(11519)
        launchApproveSwap()

        let approveSettings = openProviders(from: importHotWallet().tapToken(Constants.Token.fromName))
            .assertApproveSettingsButtonDisplayed(providerName: Constants.Provider.dex)
            .waitForProviderQuote(name: Constants.Provider.cex, containing: Constants.Token.receiveSymbol)
            .assertApproveSettingsButtonNotDisplayed(providerName: Constants.Provider.cex)
            .tapApproveSettings(providerName: Constants.Provider.dex)

        approveSettings
            .assertTitle()
            .assertPermissionDescriptionDisplayed()
            .assertLearnMoreLinkDisplayed()
            .assertAmountRow(tokenSymbol: Constants.Token.fromSymbol, policy: .transaction)
            .assertConfirmButtonDisplayed()

        approveSettings
            .openPolicyMenu(currentPolicy: .transaction)
            .assertPolicyOptionsDisplayed()
            .assertPolicySelectedInMenu(.transaction)
            .selectPolicy(.transaction)
            .assertAmountRow(tokenSymbol: Constants.Token.fromSymbol, policy: .transaction)
            .openLearnMoreAndAssertArticleHost(Constants.learnMoreHost)
    }

    func testApproveForTransactionAmountWithSingleSignature() {
        setAllureId(582)
        launchApproveSwap()

        let swapScreen = openProviders(from: importHotWallet().tapToken(Constants.Token.fromName))
            .assertApproveSettingsButtonDisplayed(providerName: Constants.Provider.dex)
            .selectProviderAndWaitForClose(name: Constants.Provider.dex)
            .verifyProviderName(contains: Constants.Provider.dex)
            .assertFeeAmountContainsFiat()

        let newTransactions = confirmSwapAndCollectTransactions(swapScreen)

        XCTContext.runActivity(named: "Verify approve for the swap amount was sent with the swap after one signature") { _ in
            XCTAssertEqual(newTransactions.count, Constants.approveAndSwapTransactionsCount, "Approve and swap should be sent together after one signature")
            XCTAssertEqual(
                EthereumTransactionJournal.approveAmounts(in: newTransactions, spender: Constants.Provider.dexSpender),
                [Constants.ApproveAmount.swapAmount],
                "Approve should be granted only for the swap amount"
            )
        }
    }

    func testUnlimitedApproveIsKeptForNextSwap() {
        setAllureId(581)
        launchApproveSwap()

        let swapScreen = openProviders(from: importHotWallet().tapToken(Constants.Token.fromName))
            .tapApproveSettings(providerName: Constants.Provider.dex)
            .openPolicyMenu(currentPolicy: .transaction)
            .selectPolicy(.unlimited)
            .assertAmountRow(tokenSymbol: Constants.Token.fromSymbol, policy: .unlimited)
            .tapConfirm()
            .selectProviderAndWaitForClose(name: Constants.Provider.dex)
            .verifyProviderName(contains: Constants.Provider.dex)
            .assertFeeAmountContainsFiat()

        let newTransactions = confirmSwapAndCollectTransactions(swapScreen)

        XCTContext.runActivity(named: "Verify unlimited approve was sent with the swap after one signature") { _ in
            XCTAssertEqual(newTransactions.count, Constants.approveAndSwapTransactionsCount, "Approve and swap should be sent together after one signature")
            XCTAssertEqual(
                EthereumTransactionJournal.approveAmounts(in: newTransactions, spender: Constants.Provider.dexSpender),
                [Constants.ApproveAmount.unlimited],
                "Unlimited approve should be granted"
            )
            XCTAssertEqual(
                wireMockClient.getScenarioStateSync(Constants.Scenario.polOneInchAllowance),
                Constants.State.approved,
                "1inch allowance for POL should become unlimited after the approve is broadcast"
            )
        }

        openProviders(from: SendFinishScreen(app).tapCloseButton())
            .assertProviderAvailable(name: Constants.Provider.dex)
            .waitForProviderQuote(name: Constants.Provider.dex, containing: Constants.Token.receiveSymbol)
            .assertApproveSettingsButtonNotDisplayed(providerName: Constants.Provider.dex)
    }

    private func launchApproveSwap() {
        launchApp(
            tangemApiType: .mock,
            expressApiType: .mock,
            clearStorage: true,
            scenarios: [
                ScenarioConfig(name: Constants.Scenario.userTokens, initialState: Constants.State.hotWalletSvS),
                ScenarioConfig(name: Constants.Scenario.quotes, initialState: Constants.State.polygonUSDC),
                ScenarioConfig(name: Constants.Scenario.expressAssets, initialState: Constants.State.bitcoinExchangeEnabled),
                ScenarioConfig(name: Constants.Scenario.exchangeQuoteEthereum, initialState: Constants.State.oneInchApprovalRequired),
                ScenarioConfig(name: Constants.Scenario.polOneInchAllowance, initialState: Constants.State.notApproved),
            ]
        )
    }

    private func openProviders(from tokenScreen: TokenScreen) -> SendSwapProviderSelectorScreen {
        XCTContext.runActivity(named: "Open swap providers for \(Constants.Token.fromSymbol) to \(Constants.Token.receiveSymbol)") { _ in
            tokenScreen
                .waitForNonZeroTotalBalance()
                .tapSwapButton()
                .closeStoriesIfNeeded()
                .validateSwapScreenDisplayed()
                .waitFromTokenDisplayed(tokenSymbol: Constants.Token.fromSymbol)
                .chooseReceiveToken(Constants.Token.receiveName)
                .waitToTokenDisplayed(tokenSymbol: Constants.Token.receiveSymbol)
                .enterFromAmount(Constants.inputAmount)
                .waitForFromAmountValue(Constants.inputAmount)
                .assertFeeAmountContainsFiat()
                .tapProviderBlock()
                .waitForDisplay()
        }
    }

    private func confirmSwapAndCollectTransactions(_ swapScreen: SwapScreen) -> [String] {
        let previousTransactions = transactionJournal.sentRawTransactions()

        swapScreen
            .confirmSwapUntilFinishOpened { transactionJournal.sentRawTransactions().count == previousTransactions.count }
            .assertHeaderTitle(Constants.swapInProgressTitle)

        return transactionJournal.collectNewRawTransactions(
            after: previousTransactions,
            expectedCount: Constants.approveAndSwapTransactionsCount
        )
    }
}

private extension SwapApproveUITests {
    enum Constants {
        static let inputAmount = "50"
        static let swapInProgressTitle = "Swap in progress"
        static let learnMoreHost = "tangem.com"
        static let approveAndSwapTransactionsCount = 2

        enum Token {
            static let fromName = "POL (ex-MATIC)"
            static let fromSymbol = "POL"
            static let receiveName = "Ethereum"
            static let receiveSymbol = "ETH"
        }

        enum Provider {
            static let dex = "1Inch"
            static let cex = "Changelly"
            static let dexSpender = "0x1111111254eeb25477b68fb85ed929f73a960582"
        }

        enum ApproveAmount {
            static let swapAmount = "000000000000000000000000000000000000000000000002b5e3af16b1880000"
            static let unlimited = String(repeating: "f", count: 64)
        }

        enum Scenario {
            static let userTokens = "user_tokens_api"
            static let quotes = "quotes_api"
            static let expressAssets = "express_api_assets"
            static let exchangeQuoteEthereum = "exchange_quote_ethereum"
            static let polOneInchAllowance = "swap_pol_1inch_allowance"
        }

        enum State {
            static let hotWalletSvS = "HotWalletSvS"
            static let polygonUSDC = "PolygonUSDC"
            static let bitcoinExchangeEnabled = "BitcoinExchangeEnabled"
            static let oneInchApprovalRequired = "OneInchApprovalRequired"
            static let notApproved = "NotApproved"
            static let approved = "Approved"
        }
    }
}
