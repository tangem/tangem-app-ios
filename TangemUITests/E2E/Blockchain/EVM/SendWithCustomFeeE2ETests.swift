//
//  SendWithCustomFeeE2ETests.swift
//  TangemUITests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class SendWithCustomFeeE2ETests: E2EBaseTestCase {
    private let sendAmount = "0.1"

    func testSendWithCustomFeeShowsOnSuccess() {
        setAllureId(13954)

        let (main, network) = launchAndImportE2EWallet()

        guard network.accountAddresses.count == 2 else {
            return XCTFail("The Send test needs exactly two account addresses (qa-tools defaultAddress + customAddress)")
        }

        var mainScreen = main
        for _ in 0 ..< network.accountAddresses.count {
            mainScreen = mainScreen
                .expandAllAccounts()
                .tapAddTokensForEmptyAccount()
                .search(network.searchQuery)
                .verifyTokenRowExists(coinId: network.coinId)
                .expandTokenIfNeeded(coinId: network.coinId)
                .enableNetworkAndSaveIfNeeded(network.networkName)
                .goBackToMain()
        }

        mainScreen = mainScreen.expandAllAccounts()
        mainScreen.verifyTokenBalanceNonNegative(network.mainScreenToken)

        let accountCount = network.accountAddresses.count
        let firstBalance = mainScreen.tokenFiatBalanceNumeric(tokenName: network.mainScreenToken, accountIndex: 0, accountCount: accountCount)
        let secondBalance = mainScreen.tokenFiatBalanceNumeric(tokenName: network.mainScreenToken, accountIndex: 1, accountCount: accountCount)

        XCTAssertGreaterThan(
            max(firstBalance, secondBalance), 0,
            "At least one account must hold a balance to send from"
        )

        let senderIndex = firstBalance >= secondBalance ? 0 : 1
        let recipientAddress = network.accountAddresses[1 - senderIndex]

        let summaryScreen = mainScreen
            .tapToken(network.mainScreenToken, atAccountIndex: senderIndex)
            .tapSendButton()
            .waitForDisplay()
            .enterAmount(sendAmount)
            .tapNextButton()
            .enterDestination(recipientAddress)
            .tapNextButtonToSummary()
            .waitForDisplay(checkValidatorBlock: false)

        let marketFee = summaryScreen.getNetworkFeeValue()
        XCTContext.runActivity(named: "Market network fee: \(marketFee); send amount: \(sendAmount) \(network.searchQuery)") { _ in }

        summaryScreen
            .tapFeeBlock()
            .waitForDisplay(cryptoSymbol: network.searchQuery, fiatSymbol: "$")
            .selectCustom()
            .verifyCustomOptionSelected()
            .waitForCustomFields()
            .setMaxFeePerGasAboveMarket(byPercent: 20)
            .tapFeeSelectorDone()

        let customFee = summaryScreen.getNetworkFeeValue()
        XCTContext.runActivity(named: "Summary network fee after custom (+20%): \(customFee); send amount: \(sendAmount) \(network.searchQuery)") { _ in }

        summaryScreen
            .tapSendButton()
            .waitForDisplay()
            .reportNetworkFee()
            .reportTransactionLink()
    }
}
