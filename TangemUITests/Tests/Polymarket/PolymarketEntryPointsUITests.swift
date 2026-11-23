//
//  PolymarketEntryPointsUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class PolymarketEntryPointsUITests: PolymarketUITestCase {
    func testPolymarket_entryPointsBeforeAndAfterOnboarding() {
        setAllureId(12894)
        let statusRequestsBefore = wireMockRequestCount(urlPattern: Constants.walletStatusPattern)

        let mainScreen = launchPolymarketWithHotWallet()
        waitForWireMockRequestCount(urlPattern: Constants.walletStatusPattern, toExceed: statusRequestsBefore)

        mainScreen
            .verifyAccountNotVisible(Localization.predictionAccountTitle)
            .openMarketsSheet()
            .verifyPolymarketWidgetDisplayed()
            .openPolymarket()
            .waitForWelcome()
            .confirmOnboarding()
            .waitForScreen()
            .closeOnboardingStoriesIfDisplayed()
            .goBack()
            .verifyAccountVisible(Localization.predictionAccountTitle)
            .openMarketsSheet()
            .verifyPolymarketWidgetDisplayed()
    }
}

private extension PolymarketEntryPointsUITests {
    enum Constants {
        static let walletStatusPattern = "\(PolymarketUITestsConstants.Path.walletStatus)(\\?.*)?"
    }
}
