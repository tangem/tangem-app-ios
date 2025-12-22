//
//  SendAmountUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class SendAmountUITests: BaseTestCase {
    func testAmountScreen_AmountEntryValidation() {
        setAllureId(4761)

        launchApp(tangemApiType: .mock)

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(Constants.tokenName)
            .tapSendButton()
            .waitForDisplay()
            .enterAmount(Constants.AmountValidation.validAmount)
            .waitForAmountValue(Constants.AmountValidation.validAmount)
            .waitForTotalExceedsBalanceBannerNotExists()
            .waitForNextButtonEnabled()
            .clearAmount()
            .enterAmount(Constants.AmountValidation.exceedingAmount)
            .waitForAmountValue(Constants.AmountValidation.exceedingAmount)
            .waitForTotalExceedsBalanceBanner()
            .waitForNextButtonDisabled()
            .clearAmount()
            .tapMaxButton()
            .waitForAmountIsNotEmpty()
            .waitForNextButtonEnabled()
            .tapCloseButton()
            .waitForTokenName(Constants.tokenName)
    }

    func testAmountScreen_CurrencyEquivalentSwitching() {
        setAllureId(4762)

        launchApp(tangemApiType: .mock)

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(Constants.tokenName)
            .tapSendButton()
            .waitForDisplay()
            .enterAmount(Constants.CurrencySwitching.sendAmount)
            .validateCurrencySymbol(Constants.CurrencySwitching.cryptoCurrencySymbol)
            .waitForFiatAmount(Constants.CurrencySwitching.expectedFiatAmount)
            .toggleCurrency()
            .validateCurrencySymbol(Constants.CurrencySwitching.fiatCurrencySymbol)
            .waitForCryptoAmount(Constants.CurrencySwitching.expectedCryptoAmount)
            .toggleCurrency()
            .validateCurrencySymbol(Constants.CurrencySwitching.cryptoCurrencySymbol)
            .waitForFiatAmount(Constants.CurrencySwitching.expectedFiatAmount)
    }
}

private extension SendAmountUITests {
    enum Constants {
        static let tokenName = "Ethereum"

        enum AmountValidation {
            static let validAmount = "0.001"
            static let exceedingAmount = "999,999,999"
        }

        enum CurrencySwitching {
            static let sendAmount = "1"
            static let cryptoCurrencySymbol = "ETH"
            static let fiatCurrencySymbol = "$"
            static let expectedCryptoAmount = "ETH\u{00A0}1.00"
            static let expectedFiatAmount = "$2,535.63"
        }
    }
}
