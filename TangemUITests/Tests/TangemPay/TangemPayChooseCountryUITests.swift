//
//  TangemPayChooseCountryUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TangemPayChooseCountryUITests: TangemPayResidencyUITestCase {
    func testGetTangemPayInDetails_FollowsPaymentAccountState() {
        setAllureId(12752)

        let details = launchWithoutTangemPay().openDetails()
        let kycRequestsBefore = requestCount(.kycAccessToken)

        openCountrySelectionFromDetails(details)
            .selectRow(Country.unitedStates)
            .waitForScreen(title: Localization.tangempayResidencyTitleState)
            .selectRow(State.alabama)
            .waitForClosed(title: Localization.tangempayResidencyTitleState)

        verifyRequested(.kycAccessToken, since: kycRequestsBefore)

        details
            .verifyGetTangemPayNotVisible()
            .goBackToMain()
            .verifyTangemPayTileShowsKycInProgress()
            .openTangemPayKycStatusSheet()
            .waitForSheet()
            .hideVerificationFromMain()
            .verifyTangemPayTileNotVisible()
            .openDetails()
            .verifyGetTangemPayVisible()
    }

    func testClosingCountryStep_ReturnsToDetails_WhenStartedFromGetTangemPay() {
        setAllureId(12753)

        let details = launchWithoutTangemPay().openDetails()

        openCountrySelectionFromDetails(details)
            .close(to: DetailsScreen.self)
            .assertContactSupportButtonExists()
    }

    func testClosingCountryStep_ShowsActionRequired_WhenStartedFromBanner() {
        setAllureId(12754)

        let onboarding = launchWithoutTangemPay(isBannerShown: true)
            .verifyGetTangemPayBannerExists()
            .tapGetTangemPayBanner()

        openCountrySelection(from: onboarding)
            .close(to: MainScreen.self)
            .verifyGetTangemPayBannerNotDisplayed()
            .verifyTangemPayTileShowsActionRequired()
            .openTangemPayResidency()
            .waitForScreen(title: Localization.tangempayResidencyTitleCountry)
    }

    func testCountriesAndStates_SplitIntoSuggestedAndFullLists() {
        setAllureId(12757)

        let details = launchWithoutTangemPay().openDetails()
        let countriesRequestsBefore = requestCount(.countries)
        let regionsRequestsBefore = requestCount(.usRegions)

        let countrySelection = openCountrySelectionFromDetails(details)
        verifyRequested(.countries, since: countriesRequestsBefore)

        countrySelection
            .verifySectionHeaderDisplayed(Localization.tangempayResidencySuggestedCountry)
            .verifySectionHeaderDisplayed(Localization.tangempayResidencyAllCountry)
            .verifyRowCount(Country.unitedStates, equals: 2)
            .verifyRowCount(Country.germany, equals: 1)
            .selectRow(Country.unitedStates)
            .waitForScreen(title: Localization.tangempayResidencyTitleState)

        verifyRequested(.usRegions, since: regionsRequestsBefore)

        countrySelection
            .verifySectionHeaderDisplayed(Localization.tangempayResidencySuggestedState)
            .verifySectionHeaderDisplayed(Localization.tangempayResidencyAllState)
            .verifyRowCount(State.california, equals: 2)
            .verifyRowCount(State.alabama, equals: 1)
    }

    func testSuggestedSections_Hidden_WhenNothingIsSuggested() {
        setAllureId(12758)

        let details = launchWithoutTangemPay(geo: .noSuggested).openDetails()
        let countriesRequestsBefore = requestCount(.countries)
        let regionsRequestsBefore = requestCount(.usRegions)

        let countrySelection = openCountrySelectionFromDetails(details)
        verifyRequested(.countries, since: countriesRequestsBefore)

        countrySelection
            .verifyRowCount(Country.unitedStates, equals: 1)
            .verifySectionHeaderNotDisplayed(Localization.tangempayResidencySuggestedCountry)
            .selectRow(Country.unitedStates)
            .waitForScreen(title: Localization.tangempayResidencyTitleState)

        verifyRequested(.usRegions, since: regionsRequestsBefore)

        countrySelection
            .verifyRowCount(State.california, equals: 1)
            .verifySectionHeaderNotDisplayed(Localization.tangempayResidencySuggestedState)
    }

    func testCountryAndStateSearch_FiltersListsAndShowsZeroState() {
        setAllureId(12759)

        let details = launchWithoutTangemPay().openDetails()
        let countriesRequestsBefore = requestCount(.countries)

        let countrySelection = openCountrySelectionFromDetails(details)
        verifyRequested(.countries, since: countriesRequestsBefore)

        countrySelection
            .verifyRowsDisplayed([Country.unitedStates])
            .search(Constants.Search.countryQuery)
            .verifyRowsDisplayed([Country.bulgaria, Country.burundi])
            .verifyRowNotDisplayed(Country.germany)
            .verifySectionHeaderNotDisplayed(Localization.tangempayResidencySuggestedCountry)
            .verifySectionHeaderNotDisplayed(Localization.tangempayResidencyAllCountry)
            .clearSearch()
            .search(Constants.Search.noResultsQuery)
            .verifySearchEmptyState()
            .clearSearch()
            .verifyRowsDisplayed([Country.bulgaria, Country.burundi, Country.germany, Country.kazakhstan, Country.unitedStates])
            .search(Constants.Search.unitedStatesQuery)
            .selectRow(Country.unitedStates)
            .waitForScreen(title: Localization.tangempayResidencyTitleState)
            .search(Constants.Search.stateQuery)
            .verifyRowsDisplayed([State.northDakota, State.southDakota])
            .verifyRowNotDisplayed(State.alabama)
            .verifySectionHeaderNotDisplayed(Localization.tangempayResidencySuggestedState)
            .verifySectionHeaderNotDisplayed(Localization.tangempayResidencyAllState)
            .clearSearch()
            .search(Constants.Search.noResultsQuery)
            .verifySearchEmptyState()
    }

    func testCountriesAndRegions_RequestedAgain_WhenCountryStepReopened() {
        setAllureId(12760)

        let mainScreen = launchWithoutTangemPay(isBannerShown: true).verifyGetTangemPayBannerExists()
        let countriesRequestsBeforeBanner = requestCount(.countries)
        let regionsRequestsBeforeBanner = requestCount(.usRegions)

        let countrySelection = openCountrySelection(from: mainScreen.tapGetTangemPayBanner())
        verifyRequested(.countries, since: countriesRequestsBeforeBanner)

        countrySelection
            .selectRow(Country.unitedStates)
            .waitForScreen(title: Localization.tangempayResidencyTitleState)
        verifyRequested(.usRegions, since: regionsRequestsBeforeBanner)

        let countriesRequestsBeforeTile = requestCount(.countries)
        let regionsRequestsBeforeTile = requestCount(.usRegions)

        countrySelection
            .close(to: MainScreen.self)
            .verifyTangemPayTileShowsActionRequired()
            .openTangemPayResidency()
            .waitForScreen(title: Localization.tangempayResidencyTitleCountry)
        verifyRequested(.countries, since: countriesRequestsBeforeTile)

        countrySelection
            .selectRow(Country.unitedStates)
            .waitForScreen(title: Localization.tangempayResidencyTitleState)
        verifyRequested(.usRegions, since: regionsRequestsBeforeTile)

        let countriesRequestsBeforeRelaunch = requestCount(.countries)
        let regionsRequestsBeforeRelaunch = requestCount(.usRegions)

        relaunchKeepingState()
            .verifyTangemPayTileShowsActionRequired()
            .openTangemPayResidency()
            .waitForScreen(title: Localization.tangempayResidencyTitleCountry)
        verifyRequested(.countries, since: countriesRequestsBeforeRelaunch)

        countrySelection
            .selectRow(Country.unitedStates)
            .waitForScreen(title: Localization.tangempayResidencyTitleState)
        verifyRequested(.usRegions, since: regionsRequestsBeforeRelaunch)
    }

    func testEligibleState_ChecksEligibilityAndOpensKyc() {
        setAllureId(12778)

        let details = launchWithoutTangemPay().openDetails()
        let countriesRequestsBefore = requestCount(.countries)
        let regionsRequestsBefore = requestCount(.usRegions)
        let eligibilityChecksBefore = requestCount(.alabamaEligibilityCheck)
        let kycRequestsBefore = requestCount(.kycAccessToken)

        let countrySelection = openCountrySelectionFromDetails(details)
        verifyRequested(.countries, since: countriesRequestsBefore)

        countrySelection
            .selectRow(Country.unitedStates)
            .waitForScreen(title: Localization.tangempayResidencyTitleState)
        verifyRequested(.usRegions, since: regionsRequestsBefore)
        verifyNotRequested(.kycAccessToken, since: kycRequestsBefore)

        countrySelection.selectRow(State.alabama)
        verifyRequested(.alabamaEligibilityCheck, since: eligibilityChecksBefore)
        verifyRequested(.kycAccessToken, since: kycRequestsBefore)
        verifyRequestedInOrder(.alabamaEligibilityCheck, then: .kycAccessToken)
    }
}

private extension TangemPayChooseCountryUITests {
    enum Constants {
        enum Search {
            static let countryQuery = "bu"
            static let stateQuery = "ko"
            static let unitedStatesQuery = "United"
            static let noResultsQuery = "qwerty"
        }
    }
}
