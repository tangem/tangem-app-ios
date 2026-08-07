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
}
