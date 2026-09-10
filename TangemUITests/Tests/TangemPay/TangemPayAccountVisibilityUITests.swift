//
//  TangemPayAccountVisibilityUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TangemPayAccountVisibilityUITests: BaseTestCase {
    private let firstAccountName = "Account 1"
    private let secondAccountName = "Account 2"
    private let payAccountName = "Payment account"

    func testPayAccountNotListedInWalletSettingsAccounts() {
        setAllureId(11470)

        launchWithPayAndTwoAccounts()
            .openDetails()
            .openWalletSettings()
            .verifyAccountExists(firstAccountName)
            .verifyAccountExists(secondAccountName)
            .verifyAccountNotExists(payAccountName)
    }

    func testPayAccountNotOfferedWhenAddingTokenViaAddAndManage() {
        setAllureId(11469)

        launchWithPayAndTwoAccounts()
            .openAddTokensAccountPicker()
            .verifyAccountVisible(firstAccountName)
            .verifyAccountVisible(secondAccountName)
            .verifyAccountNotVisible(payAccountName)
    }

    func testPayAccountNotListedInAddFundsTokenSelector() {
        setAllureId(11475)

        // Only the main account is asserted: a token selector lists an account solely when it holds a suitable token.
        launchWithPayAndTwoAccounts()
            .tapMainBuy()
            .waitBuyTokenSelectorDisplayed()
            .verifyAccountVisible(firstAccountName)
            .verifyAccountNotVisible(payAccountName)
    }

    func testPayAccountNotListedInTransfersTokenSelector() {
        setAllureId(11476)

        launchWithPayAndTwoAccounts()
            .tapMainSell()
            .waitSellTokenSelectorDisplayed()
            .verifyAccountVisible(firstAccountName)
            .verifyAccountNotVisible(payAccountName)
    }

    func testPayAccountNotOfferedWhenAddingTokenViaMarkets() {
        setAllureId(11468)

        launchWithPayAndTwoAccounts()
            .openMarketsSheetWithSwipe()
            .searchForToken(Constants.marketsToken)
            .openTokenDetails(Constants.marketsToken)
            .tapAddToPortfolio()
            .openAccountSelector()
            .verifyAccountVisible(firstAccountName)
            .verifyAccountVisible(secondAccountName)
            .verifyAccountNotVisible(payAccountName)
    }

    func testPayAccountNotOfferedAsReferralRewardsAddress() {
        setAllureId(11471)

        launchWithPayAndTwoAccounts()
            .openDetails()
            .openWalletSettings()
            .openReferralProgram()
            .openAccountSelector()
            .verifyAccountVisible(firstAccountName)
            .verifyAccountVisible(secondAccountName)
            .verifyAccountNotVisible(payAccountName)
    }

    private func launchWithPayAndTwoAccounts() -> MainScreen {
        launchAndImportHotWallet(
            expressApiType: .mock,
            scenarios: Constants.scenarios
        )
        .generateMissingAddressesIfNeeded()
        .verifyTangemPayTileVisible()
    }
}

private extension TangemPayAccountVisibilityUITests {
    enum Constants {
        /// Not held by either account, so Markets offers to add it.
        static let marketsToken = "Bitcoin"

        /// Two tokens per account: Add & Manage only appears once an account holds at least two.
        static let scenarios: [ScenarioConfig] = [
            ScenarioConfig(name: "user_tokens_api", initialState: "TwoAccountsSameUsdt"),
            ScenarioConfig(name: "eth_call_api", initialState: "Started"),
            ScenarioConfig(name: "eth_network_balance", initialState: "Started"),
        ]
    }
}
