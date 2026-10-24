//
//  TangemPayRegionUnavailableUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TangemPayRegionUnavailableUITests: TangemPayResidencyUITestCase {
    func testUnavailableRegion_OpensRegionUnavailableScreen() {
        setAllureId(12761)

        let details = launchWithoutTangemPay(isRegionUnavailable: true).openDetails()
        let countryChecksBefore = requestCount(.kazakhstanEligibilityCheck)
        let stateChecksBefore = requestCount(.alabamaEligibilityCheck)

        let unavailableRegion = openCountrySelectionFromDetails(details)
            .selectRowExpectingUnavailableRegion(Country.kazakhstan)
            .waitForScreen()
        verifyRequested(.kazakhstanEligibilityCheck, since: countryChecksBefore)

        unavailableRegion
            .verifyContent()
            .tapSelectAnotherRegion()
            .waitForScreen(title: Localization.tangempayResidencyTitleCountry)
            .selectRow(Country.unitedStates)
            .waitForScreen(title: Localization.tangempayResidencyTitleState)
            .selectRowExpectingUnavailableRegion(State.alabama)
            .waitForScreen()
        verifyRequested(.alabamaEligibilityCheck, since: stateChecksBefore)

        unavailableRegion
            .close(to: DetailsScreen.self)
            .assertContactSupportButtonExists()
    }

    func testJoinWaitlistForm_ShowsContentWithFocusedEmail() {
        setAllureId(12762)

        let details = launchWithoutTangemPay(isRegionUnavailable: true).openDetails()
        let countryChecksBefore = requestCount(.kazakhstanEligibilityCheck)

        let unavailableRegion = openCountrySelectionFromDetails(details)
            .selectRowExpectingUnavailableRegion(Country.kazakhstan)
            .waitForScreen()
        verifyRequested(.kazakhstanEligibilityCheck, since: countryChecksBefore)

        unavailableRegion
            .tapJoinWaitlist()
            .waitForSheet()
            .verifyEmailFieldFocused()
            .verifyContent()
    }

    func testJoinWaitlist_SendsStateAndMarketingConsent_WhenUsStateUnavailable() {
        setAllureId(12763)

        let details = launchWithoutTangemPay(isRegionUnavailable: true).openDetails()
        let waitlistRequestsBefore = waitlistRequestCount()

        openCountrySelectionFromDetails(details)
            .selectRow(Country.unitedStates)
            .waitForScreen(title: Localization.tangempayResidencyTitleState)
            .selectRowExpectingUnavailableRegion(State.alabama)
            .waitForScreen()
            .tapJoinWaitlist()
            .waitForSheet()
            .verifyEmailFieldFocused()
            .enterEmail(Constants.Email.invalid)
            .tapSave()
            .verifyEmailFormatError()
            .enterEmail(Constants.Email.valid)
            .tapMarketingConsent()
            .saveExpectingJoined()
            .verifyGetTangemPayVisible()
            .goBackToMain()
            .verifyTangemPayTileNotVisible()

        verifyWaitlistJoined(
            with: TangemPayWaitlistRequest(
                email: Constants.Email.valid,
                marketingConsent: true,
                countryCode: Constants.CountryCode.unitedStates,
                regionCode: Constants.RegionCode.alabama
            ),
            since: waitlistRequestsBefore
        )
    }

    func testJoinWaitlist_SendsCountryWithoutMarketingConsent_WhenCountryUnavailable() {
        setAllureId(12776)

        let details = launchWithoutTangemPay(isRegionUnavailable: true).openDetails()
        let waitlistRequestsBefore = waitlistRequestCount()

        openCountrySelectionFromDetails(details)
            .selectRowExpectingUnavailableRegion(Country.kazakhstan)
            .waitForScreen()
            .tapJoinWaitlist()
            .waitForSheet()
            .verifyEmailFieldFocused()
            .enterEmail(Constants.Email.valid)
            .saveExpectingJoined()
            .verifyGetTangemPayVisible()
            .goBackToMain()
            .verifyTangemPayTileNotVisible()

        verifyWaitlistJoined(
            with: TangemPayWaitlistRequest(
                email: Constants.Email.valid,
                marketingConsent: false,
                countryCode: Constants.CountryCode.kazakhstan,
                regionCode: nil
            ),
            since: waitlistRequestsBefore
        )
    }

    func testHideAccountFromHome_HidesPaymentAccount_WhenRegionUnavailable() {
        setAllureId(12765)

        openRegionUnavailablePopupFromMain()
            .tapHideAccount()
            .verifyTangemPayTileNotVisible()
            .openDetails()
            .verifyGetTangemPayVisible()
    }

    func testRegionUnavailableSheet_ShowsContentAndReopensCountryStep() {
        setAllureId(12766)

        openRegionUnavailablePopupFromMain()
            .verifyContent()
            .tapSelectAnotherRegion()
            .waitForScreen(title: Localization.tangempayResidencyTitleCountry)
    }

    private func openRegionUnavailablePopupFromMain() -> TangemPayRegionUnavailablePopup {
        let details = launchWithoutTangemPay(isRegionUnavailable: true).openDetails()

        return openCountrySelectionFromDetails(details)
            .selectRowExpectingUnavailableRegion(Country.kazakhstan)
            .waitForScreen()
            .close(to: DetailsScreen.self)
            .goBackToMain()
            .verifyTangemPayTileShowsActionRequired()
            .openTangemPayRegionUnavailablePopup()
            .waitForSheet()
    }
}

private extension TangemPayRegionUnavailableUITests {
    enum Constants {
        enum Email {
            static let invalid = "pupupu@bubu"
            static let valid = "pupu@bubug.com"
        }

        enum CountryCode {
            static let unitedStates = "US"
            static let kazakhstan = "KZ"
        }

        enum RegionCode {
            static let alabama = "US-AL"
        }
    }
}
