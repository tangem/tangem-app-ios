//
//  TangemPayBankOfframpHiddenBalancesUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TangemPayBankOfframpHiddenBalancesUITests: TangemPayBankOfframpUITestCase {
    func testWithdrawWithinPortfolio_MasksPaymentAccountAndTokenListBalances() {
        setAllureId(12747)

        openPaymentAccount(extraScenarios: Constants.swapScenarios, extraLaunchArguments: [Constants.hideBalancesArgument])
            .tapWithdrawOpeningHub()
            .tapWithinPortfolio()
            .verifyFromBalance(contains: Constants.mask)
            .openEmptyTokenSelector(revealing: Constants.bitcoinName)
            .verifyTokenBalancesMasked(Constants.bitcoinName, mask: Constants.mask)
    }

    func testBankOfframp_MasksSelectedTokenAndSourceListBalances() {
        setAllureId(12748)

        openPaymentAccount(balance: .arbitrumTopUp, extraLaunchArguments: [Constants.hideBalancesArgument])
            .tapWithdrawOpeningHub()
            .tapToPersonalAccount()
            .verifySourceTokenBalance(Constants.mask, network: TangemPayNetwork.polygon.displayName)
            .tapSourceToken()
            .verifyAvailableToken(symbol: Constants.usdcSymbol, network: .polygon, balance: Constants.mask, isSelected: true)
            .verifyAvailableToken(symbol: Constants.usdcSymbol, network: .arbitrum, balance: Constants.mask, isSelected: false)
            .verifyUnavailableToken(symbol: Constants.usdtSymbol, network: .bsc)
            .verifyTokenCount(Constants.sourceTokenCount)
    }

    func testBankOfframpToRecentRecipient_MasksConfirmationBalance() {
        setAllureId(12750)

        openPaymentAccount(balance: .bankOfframp, bankAccounts: .twoAccounts, extraLaunchArguments: [Constants.hideBalancesArgument])
            .tapWithdrawOpeningHub()
            .tapRecentRecipient(.john)
            .enterAmount(Constants.transferAmount)
            .selectSourceToken(symbol: Constants.usdcSymbol, network: .polygon)
            .tapContinueToConfirmation()
            .verifyAmountCard(amount: Constants.sentAmount, balance: Constants.mask)
    }
}

private extension TangemPayBankOfframpHiddenBalancesUITests {
    enum Constants {
        static let hideBalancesArgument = "-uitest-hide-balances"
        static let mask = "\u{2217}\u{2217}\u{2217}"
        static let bitcoinName = "Bitcoin"
        static let usdcSymbol = "USDC"
        static let usdtSymbol = "USDT"
        static let sourceTokenCount = 3
        static let transferAmount = "5"
        static let sentAmount = "$5"

        static let swapScenarios = [
            ScenarioConfig(name: "bitcoin_utxo", initialState: "Balance"),
            ScenarioConfig(name: "express_api_assets", initialState: "BitcoinExchangeEnabled"),
        ]
    }
}
