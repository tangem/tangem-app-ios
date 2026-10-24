//
//  SwapGeoRestrictionsUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class SwapGeoRestrictionsUITests: BaseTestCase {
    func testRestrictionForOneProvider() {
        setAllureId(11595)

        launchApp(
            tangemApiType: .mock,
            expressApiType: .mock,
            scenarios: [
                ScenarioConfig(name: "exchange_quote_ethereum", initialState: "OneInchRestricted"),
            ]
        )

        let swapScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(Constants.fromTokenName)
            .waitForNonZeroTotalBalance()
            .tapSwapButton()
            .closeStoriesIfNeeded()
            .validateSwapScreenDisplayed()
            .chooseReceiveToken(Constants.receiveTokenName)
            .enterFromAmount(Constants.inputAmount)
            .assertReceiveAmountIsNotZero()
            .verifyProviderName(contains: Constants.availableProviderName)
            .waitForNotificationNotShown(title: Constants.restrictionsTitle)
            .waitForConfirmButtonEnabled()

        swapScreen
            .tapProviderBlock()
            .waitForDisplay()
            .assertProviderUnavailable(name: Constants.restrictedProviderName)
            .assertProviderAvailable(name: Constants.availableProviderName)
            .selectProviderAndWaitForClose(name: Constants.restrictedProviderName)
            .verifyProviderName(contains: Constants.restrictedProviderName)
            .waitForNotificationShown(title: Constants.restrictionsTitle)
            .waitForConfirmButtonDisabled()
    }
}

private extension SwapGeoRestrictionsUITests {
    enum Constants {
        static let fromTokenName = "Ethereum"
        static let receiveTokenName = "POL (ex-MATIC)"
        static let inputAmount = "0.1"
        static let restrictedProviderName = "1Inch"
        static let availableProviderName = "LI.FI"
        static let restrictionsTitle = "Regional swap restrictions"
    }
}
