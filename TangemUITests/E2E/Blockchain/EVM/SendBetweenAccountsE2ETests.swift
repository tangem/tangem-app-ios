//
//  SendBetweenAccountsE2ETests.swift
//  TangemUITests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class SendBetweenAccountsE2ETests: E2EBaseTestCase {
    private let sendAmount = "0.1"

    func testSendFromRicherAccountToOther() {
        setAllureId(13674)

        let (main, network) = launchAndImportE2EWallet()

        XCTAssertEqual(
            network.accountAddresses.count, 2,
            "The Send test needs two account addresses from the catalog (qa-tools defaultAddress + customAddress)"
        )

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

        mainScreen
            .tapToken(network.mainScreenToken, atAccountIndex: senderIndex)
            .tapSendButton()
            .waitForDisplay()
            .enterAmount(sendAmount)
            .tapNextButton()
            .enterDestination(recipientAddress)
            .tapNextButtonToSummary()
            .waitForDisplay(checkValidatorBlock: false)
            .tapSendButton()
            .waitForDisplay()
            .reportTransactionLink()
    }
}
