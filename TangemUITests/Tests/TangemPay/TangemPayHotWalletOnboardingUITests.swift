//
//  TangemPayHotWalletOnboardingUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TangemPayHotWalletOnboardingUITests: BaseTestCase {
    func testCardIssuing_StartsFromBanner_WhenHotWalletIsCreated() {
        setAllureId(10666)

        launchWithoutWallet(
            eligibilityState: "Started",
            extraScenarios: [ScenarioConfig(name: "tangem_pay_eligibility_channels", initialState: "Banner")]
        )

        let mainScreen = CreateWalletSelectorScreen(app)
            .createMobileWallet()
            .skipPushNotificationsSetup()
            .verifyGetTangemPayBannerExists()

        let countrySelection = mainScreen
            .tapGetTangemPayBanner()
            .waitForScreen()
            .tapGetCardExpectingCountrySelection()

        // The backend turns the wallet into a Paera customer once the offer is accepted
        wireMockClient.setScenarioStateSync("tangem_pay_eligibility", state: "PaeraCustomer")

        countrySelection
            .waitForScreen(title: Localization.tangempayResidencyTitleCountry)
            .selectRow(Constants.residenceCountry)
            .waitForScreen(title: Localization.tangempayResidencyTitleState)
            .selectRow(Constants.residenceState)
            .waitForClosed(title: Localization.tangempayResidencyTitleState)

        mainScreen.verifyTangemPayTileSubtitle(contains: Localization.tangempayKycInProgress)
    }

    func testCardIssuing_StartsFromMobileOnboarding_WhenOpenedByDeeplink() {
        setAllureId(10413)

        launchWithoutWallet(
            eligibilityState: "PaeraCustomer",
            extraLaunchArguments: ["-uitest-tangempay-mobile-onboarding"]
        )

        TangemPayMobileOnboardingScreen(app)
            .waitForScreen()
            .tapGetCard()
            .skipPushNotificationsSetup()
            .verifyTangemPayTileSubtitle(contains: Localization.tangempayKycInProgress)
    }

    private func launchWithoutWallet(
        eligibilityState: String,
        extraScenarios: [ScenarioConfig] = [],
        extraLaunchArguments: [String] = []
    ) {
        launchApp(
            tangemApiType: .mock,
            visaApiType: .mock,
            clearStorage: true,
            scenarios: [
                ScenarioConfig(name: "tangem_pay_eligibility", initialState: eligibilityState),
                ScenarioConfig(name: "tangem_pay_kyc_status", initialState: "InProgress"),
            ] + extraScenarios,
            extraLaunchArguments: extraLaunchArguments
        )
    }
}

private extension TangemPayHotWalletOnboardingUITests {
    enum Constants {
        static let residenceCountry = "United States"
        static let residenceState = "California"
    }
}
