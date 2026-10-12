//
//  TangemPayOnboardingUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TangemPayOnboardingUITests: BaseTestCase {
    private let accessCode = "141261"

    func testGetTangemPayBanner_ShownOnMain_WhenBannerChannelReceived() {
        setAllureId(9632)

        launchAndImportHotWallet(
            eligibilityState: "Started",
            accessCode: accessCode,
            scenarios: [ScenarioConfig(name: "tangem_pay_eligibility_channels", initialState: "Banner")]
        )
        .verifyGetTangemPayBannerExists()
    }

    func testOnboarding_OpensFromAppDetails_WhenDetailsChannelReceived() {
        setAllureId(9673)

        launchAndImportHotWallet(
            eligibilityState: "Started",
            accessCode: accessCode,
            scenarios: [ScenarioConfig(name: "tangem_pay_eligibility_channels", initialState: "BannerAndDetails")]
        )
        .openDetails()
        .openGetTangemPay()
        .waitForScreen()
    }

    func testGetTangemPayFromAppDetails_ListsWalletsWithoutTangemPay_WhenSeveralWalletsAdded() {
        setAllureId(9637)

        launchWithTwoWalletsWithoutTangemPay()
            .openDetails()
            .openGetTangemPay()
            .waitForScreen()
            .tapGetCardExpectingWalletSelector()
            .waitForSheet()
            .verifyWalletListed(Constants.Wallet.hot)
            .verifyWalletListed(Constants.Wallet.mockCard)
    }

    /// [REDACTED_INFO] Get Tangem Pay banner skips wallet selection right after a second wallet is added and issues the offer to the first wallet
    func skipped_testGetCardFromMainBanner_OpensWalletSelection_WhenSeveralWalletsAdded() {
        setAllureId(9638)

        launchWithTwoWalletsWithoutTangemPay()
            .verifyGetTangemPayBannerExists()
            .tapGetTangemPayBanner()
            .waitForScreen()
            .tapGetCardExpectingWalletSelector()
            .waitForSheet()
            .verifyWalletListed(Constants.Wallet.hot)
            .verifyWalletListed(Constants.Wallet.mockCard)
    }

    private func launchWithTwoWalletsWithoutTangemPay() -> MainScreen {
        launchAndImportHotWallet(
            eligibilityState: "Started",
            scenarios: [ScenarioConfig(name: "tangem_pay_eligibility_channels", initialState: "BannerAndDetails")]
        )
        .addNewWallet(name: .wallet2)
        .swipeWalletRight()
    }
}

private extension TangemPayOnboardingUITests {
    enum Constants {
        enum Wallet {
            static let hot = "Wallet"
            static let mockCard = "Wallet 2"
        }
    }
}
