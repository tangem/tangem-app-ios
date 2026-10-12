//
//  DeeplinkDeliveryUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class DeeplinkDeliveryUITests: BaseTestCase {
    private let safariHelper = SafariHelper()

    func testDeeplinkFromMainScreen_OpensScreen() {
        setAllureId(11800)

        launchApp(tangemApiType: .mock)

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .waitForTotalBalanceShimmerToComplete()

        openDeeplinkFromSafari(Constants.referralDeeplink)

        ReferralScreen(app)
            .verifyReferralScreenDisplayed()
    }

    func testDeeplinkOverOpenScreen_OpensWithoutReturningToMain() {
        setAllureId(11801)

        launchApp(tangemApiType: .mock)

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .waitForTotalBalanceShimmerToComplete()
            .openDetails()

        openDeeplinkFromSafari(Constants.referralDeeplink)

        ReferralScreen(app)
            .verifyReferralScreenDisplayed()
    }

    func testDeeplinkWhileAppIsClosed_OpensOnceTheMainScreenIsUp() {
        setAllureId(11802)

        launchApp(tangemApiType: .mock)

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .waitForTotalBalanceShimmerToComplete()

        app.terminate()

        openDeeplinkFromSafari(Constants.referralDeeplink)
        app.activate()

        WelcomeBackScreen(app)
            .selectSavedWallet()
        CreateWalletSelectorScreen(app)
            .selectWalletFromList(name: .wallet2)

        ReferralScreen(app)
            .verifyReferralScreenDisplayed()
    }

    private enum Constants {
        static let referralDeeplink = "tangem://referral"
    }

    private func openDeeplinkFromSafari(_ deeplink: String) {
        XCTContext.runActivity(named: "Open \(deeplink) from Safari") { _ in
            safariHelper.safari.launch()
            safariHelper.openDeeplink(deeplink)
            safariHelper.tapOpenButton()
        }
    }
}
