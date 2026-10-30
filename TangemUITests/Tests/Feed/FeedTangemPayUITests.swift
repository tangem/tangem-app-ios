//
//  FeedTangemPayUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class FeedTangemPayUITests: BaseTestCase {
    func testFeed_tangemPayBannerDisplayedForSingleWalletWithoutPayAccount() {
        setAllureId(11661)
        launchWithBannerChannel()

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .openMarketsSheet()
            .verifyTangemPayBannerDisplayed()
    }

    func testFeed_tangemPayBannerHiddenForSingleWalletWithPayAccount() {
        setAllureId(11662)
        launchAndImportHotWallet(
            eligibilityState: Constants.State.paeraCustomer,
            scenarios: [ScenarioConfig(name: Constants.Scenario.eligibilityChannels, initialState: Constants.State.banner)]
        )
        .verifyTangemPayTileExists()
        .openMarketsSheet()
        .verifyAddAccountBannerDisplayed()
        .verifyTangemPayBannerNotDisplayed()
    }

    func testFeed_tangemPayBannerDisplayedForSeveralWalletsWithoutPayAccount() {
        setAllureId(11663)
        launchWithBannerChannel()

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet)
            .addNewWallet(name: .wallet2)
            .verifyWalletNameDisplayed(Constants.Wallet.second)
            .openMarketsSheet()
            .verifyTangemPayBannerDisplayed()
    }

    func testFeed_tangemPayBannerHiddenForSeveralWalletsWhenOneHasPayAccount() {
        setAllureId(11664)
        launchAndImportHotWallet(
            eligibilityState: Constants.State.hotWalletCustomerOnly,
            scenarios: [ScenarioConfig(name: Constants.Scenario.eligibilityChannels, initialState: Constants.State.banner)]
        )
        .verifyTangemPayTileExists()
        .addNewWallet(name: .wallet)
        .verifyWalletNameDisplayed(Constants.Wallet.second)
        .openMarketsSheet()
        .verifyAddAccountBannerDisplayed()
        .verifyTangemPayBannerNotDisplayed()
    }

    func testFeed_tangemPayBannerTapOpensOnboarding() {
        setAllureId(11665)
        launchWithBannerChannel()

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .openMarketsSheet()
            .verifyTangemPayBannerDisplayed()
            .openTangemPayOnboarding()
            .waitForScreen()
    }

    /// [REDACTED_INFO] Pay banner isn't displayed if user started KYC process
    func skipped_testFeed_tangemPayBannerTapOpensKycWhenKycNotCompleted() {
        setAllureId(12561)
        launchAndImportHotWallet(
            eligibilityState: Constants.State.paeraCustomer,
            scenarios: [ScenarioConfig(name: Constants.Scenario.kycStatus, initialState: Constants.State.kycInProgress)]
        )
        .verifyTangemPayTileSubtitle(contains: Localization.tangempayKycInProgress)
        .openMarketsSheet()
        .verifyTangemPayBannerDisplayed()
        .openTangemPayKycStatusSheet()
        .waitForSheet()
    }

    private func launchWithBannerChannel() {
        launchApp(
            tangemApiType: .mock,
            visaApiType: .mock,
            clearStorage: true,
            scenarios: [ScenarioConfig(name: Constants.Scenario.eligibilityChannels, initialState: Constants.State.banner)]
        )
    }
}

private extension FeedTangemPayUITests {
    enum Constants {
        enum Scenario {
            static let eligibilityChannels = "tangem_pay_eligibility_channels"
            static let kycStatus = "tangem_pay_kyc_status"
        }

        enum Wallet {
            static let second = "Wallet 2"
        }

        enum State {
            static let banner = "Banner"
            static let paeraCustomer = "PaeraCustomer"
            static let hotWalletCustomerOnly = "HotWalletCustomerOnly"
            static let kycInProgress = "InProgress"
        }
    }
}
