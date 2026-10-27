//
//  TangemPayHotWalletOnboardingUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TangemPayHotWalletOnboardingUITests: BaseTestCase {
    func testCardIssuing_StartsFromBanner_ForBackedUpHotWallet() {
        setAllureId(10666)

        let mainScreen = launchAndImportHotWalletWithoutSystemBanners(
            eligibilityState: "Started",
            scenarios: [
                ScenarioConfig(name: "tangem_pay_kyc_status", initialState: "Required"),
                ScenarioConfig(name: "tangem_pay_eligibility_channels", initialState: "Banner"),
            ]
        )
        .verifyGetTangemPayBannerExists()

        let countrySelection = mainScreen
            .tapGetTangemPayBanner()
            .waitForScreen()
            .tapGetCardExpectingCountrySelection()

        // The backend turns the wallet into a Paera customer once the offer is accepted
        wireMockClient.setScenarioStateSync("tangem_pay_eligibility", state: "PaeraCustomer")

        countrySelection
            .waitForScreen(title: Localization.tangempayResidencyTitleCountry)
            .verifySectionHeaderDisplayed(Localization.tangempayResidencySuggestedCountry)
            .selectRow(Constants.residenceCountry)
            .waitForScreen(title: Localization.tangempayResidencyTitleState)

        let kycRequestsBeforeState = wireMockRequestCount(urlPattern: Constants.kycAccessTokenEndpoint)

        countrySelection
            .selectRow(Constants.residenceState)
            .waitForClosed(title: Localization.tangempayResidencyTitleState)

        waitForWireMockRequestCount(urlPattern: Constants.kycAccessTokenEndpoint, toExceed: kycRequestsBeforeState)

        mainScreen
            .verifyTangemPayTileShowsActionRequired()
            .openTangemPayResidency()
            .waitForScreen(title: Localization.tangempayResidencyTitleCountry)
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

    private func launchWithoutWallet(eligibilityState: String, extraLaunchArguments: [String] = []) {
        launchApp(
            tangemApiType: .mock,
            visaApiType: .mock,
            clearStorage: true,
            scenarios: [
                ScenarioConfig(name: "tangem_pay_eligibility", initialState: eligibilityState),
                ScenarioConfig(name: "tangem_pay_kyc_status", initialState: "InProgress"),
            ],
            extraLaunchArguments: extraLaunchArguments
        )
    }
}

private extension TangemPayHotWalletOnboardingUITests {
    enum Constants {
        static let residenceCountry = "United States"
        static let residenceState = "California"
        static let kycAccessTokenEndpoint = "/bff-v2/v1/customer/kyc(\\?.*)?"
    }
}
