//
//  BuyTokenAvailabilityUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class BuyTokenAvailabilityUITests: BaseTestCase {
    func testBuy_TokenUnavailableForBuyShowsNotSupportedBanner() {
        setAllureId(588)
        let token = Constants.token

        launchApp(
            tangemApiType: .mock,
            expressApiType: .mock,
            scenarios: [ScenarioConfig(name: Constants.Scenario.userTokens, initialState: Constants.State.tether)]
        )

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapMainBuy()
            .waitBuyTokenSelectorDisplayed()
            .tapToken(token)
            .tapBuy()
            .waitForTitle("\(Localization.commonBuy) \(token)")
            .validateErrorContent(
                title: Localization.onrampTokenIsNotSupportedBannerTitle(token),
                message: Localization.onrampTokenIsNotSupportedBannerSubtitle
            )
    }
}

private extension BuyTokenAvailabilityUITests {
    enum Constants {
        static let token = "Tether"

        enum Scenario {
            static let userTokens = "user_tokens_api"
        }

        enum State {
            static let tether = "USDT"
        }
    }
}
