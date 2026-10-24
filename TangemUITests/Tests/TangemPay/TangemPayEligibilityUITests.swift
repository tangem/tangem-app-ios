//
//  TangemPayEligibilityUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TangemPayEligibilityUITests: BaseTestCase {
    func testGetTangemPayBanner_NotShownOnMain_WhenChannelsListIsEmpty() {
        setAllureId(9634)

        launchWithoutTangemPayAwaitingChannels(channelsState: Constants.State.emptyChannels)
            .verifyGetTangemPayBannerNotDisplayed()
    }

    func testGetTangemPayBanner_NotShownOnMain_WhenChannelsRequestFails() {
        setAllureId(9639)

        launchWithoutTangemPayAwaitingChannels(channelsState: Constants.State.channelsError)
            .verifyGetTangemPayBannerNotDisplayed()
    }

    func testGetTangemPayBanner_OpensOnboarding() {
        setAllureId(9672)

        launchWithoutTangemPay(channelsState: Constants.State.bannerChannel)
            .verifyGetTangemPayBannerExists()
            .tapGetTangemPayBanner()
            .waitForScreen()
    }

    func testGetTangemPay_StaysInAppDetails_WhenBannerClosed() {
        setAllureId(9635)

        launchWithoutTangemPay(channelsState: Constants.State.bannerChannel)
            .verifyGetTangemPayBannerExists()
            .tapGetTangemPayBannerLater()
            .verifyGetTangemPayBannerNotDisplayed()
            .openDetails()
            .verifyGetTangemPayVisible()
    }

    func testWalletWithoutTangemPay_ShowsNoBannerAndOffersGetTangemPayInDetails_WhenAnotherWalletHasTangemPay() {
        setAllureId(9674)

        launchAndImportHotWallet(
            eligibilityState: Constants.State.wallet2NotCustomer,
            scenarios: [ScenarioConfig(name: Constants.Scenario.channels, initialState: Constants.State.bannerChannel)],
            featureToggles: Constants.marketingBannersShownWithSystemCards
        )
        .verifyTangemPayTileExists()
        .addNewWallet(name: .wallet2)
        .verifyVisibleWalletHasNoTangemPayTile()
        .verifyGetTangemPayBannerNotDisplayed()
        .openDetails()
        .verifyGetTangemPayVisible()
    }

    private func launchWithoutTangemPayAwaitingChannels(channelsState: String) -> MainScreen {
        let channelsRequestsBefore = wireMockRequestCount(urlPattern: Constants.channelsEndpoint)
        let mainScreen = launchWithoutTangemPay(channelsState: channelsState)
        waitForWireMockRequestCount(urlPattern: Constants.channelsEndpoint, toExceed: channelsRequestsBefore)
        return mainScreen.waitForTotalBalanceDisplayed()
    }

    private func launchWithoutTangemPay(channelsState: String) -> MainScreen {
        launchAndImportHotWallet(
            eligibilityState: Constants.State.notCustomer,
            scenarios: [ScenarioConfig(name: Constants.Scenario.channels, initialState: channelsState)],
            featureToggles: Constants.marketingBannersShownWithSystemCards
        )
    }
}

private extension TangemPayEligibilityUITests {
    enum Constants {
        static let marketingBannersShownWithSystemCards = ["TWI-1841_hide_marketing_banners_while_system": false]
        static let channelsEndpoint = "/bff-v2/v1/eligibility/channels"

        enum Scenario {
            static let channels = "tangem_pay_eligibility_channels"
        }

        enum State {
            static let notCustomer = "Started"
            static let wallet2NotCustomer = "Wallet2NotCustomer"
            static let emptyChannels = "Started"
            static let channelsError = "Error"
            static let bannerChannel = "Banner"
        }
    }
}
