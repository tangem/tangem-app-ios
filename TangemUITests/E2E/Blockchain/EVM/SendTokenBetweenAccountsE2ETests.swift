//
//  SendTokenBetweenAccountsE2ETests.swift
//  TangemUITests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class SendTokenBetweenAccountsE2ETests: E2EBaseTestCase {
    func testSendTokenFromRicherAccountToOther() throws {
        setAllureId(13953)

        try XCTSkipIf(
            E2EConfig.testData.network.token == nil,
            "No token configured for this network — skipping the token Send test"
        )

        let (main, network) = launchAndImportE2EWallet()
        let token = try XCTUnwrap(network.token)

        guard network.accountAddresses.count == 2 else {
            return XCTFail("The Send test needs exactly two account addresses (qa-tools defaultAddress + customAddress)")
        }

        var mainScreen = main
        for _ in 0 ..< network.accountAddresses.count {
            mainScreen = mainScreen
                .expandAllAccounts()
                .tapAddTokensForEmptyAccount()
                .search(token.searchQuery)
                .verifyTokenRowExists(coinId: token.coinId)
                .expandTokenIfNeeded(coinId: token.coinId)
                .enableNetworkAndSaveIfNeeded(network.networkName)
                .goBackToMain()
        }

        mainScreen = mainScreen.expandAllAccounts()
        mainScreen.verifyTokenBalanceNonNegative(token.mainScreenToken)

        let accountCount = network.accountAddresses.count
        let firstBalance = mainScreen.tokenFiatBalanceNumeric(tokenName: token.mainScreenToken, accountIndex: 0, accountCount: accountCount)
        let secondBalance = mainScreen.tokenFiatBalanceNumeric(tokenName: token.mainScreenToken, accountIndex: 1, accountCount: accountCount)

        XCTAssertGreaterThan(
            max(firstBalance, secondBalance), 0,
            "At least one account must hold the token to send from"
        )

        let senderIndex = firstBalance >= secondBalance ? 0 : 1
        let recipientAddress = network.accountAddresses[1 - senderIndex]

        mainScreen
            .tapToken(token.mainScreenToken, atAccountIndex: senderIndex)
            .tapSendButton()
            .waitForDisplay()
            .enterAmount(token.sendAmount)
            .tapNextButton()
            .enterDestination(recipientAddress)
            .tapNextButtonToSummary()
            .waitForDisplay(checkValidatorBlock: false)
            .tapSendButton()
            .waitForDisplay()
            .reportTransactionLink()
    }
}
