//
//  TangemPayResidencyUITestCase.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

class TangemPayResidencyUITestCase: BaseTestCase {
    enum GeoState: String {
        case fullList = "FullList"
        case noSuggested = "NoSuggested"
    }

    enum Endpoint: String {
        case countries = "/bff-v2/v1/geo/countries(\\?.*)?"
        case usRegions = "/bff-v2/v1/geo/countries/US/regions(\\?.*)?"
        case kycAccessToken = "/bff-v2/v1/customer/kyc(\\?.*)?"
        case kazakhstanEligibilityCheck = "/bff-v2/v1/eligibility/check\\?(?=.*product=PAYMENT_ACCOUNT)(?=.*country_code=KZ)(?!.*region_code).*"
        case alabamaEligibilityCheck = "/bff-v2/v1/eligibility/check\\?(?=.*product=PAYMENT_ACCOUNT)(?=.*country_code=US)(?=.*region_code=US-AL).*"
        case waitlist = "/bff-v2/v1/waitlist"
    }

    enum Country {
        static let unitedStates = "United States"
        static let germany = "Germany"
        static let bulgaria = "Bulgaria"
        static let burundi = "Burundi"
        static let kazakhstan = "Kazakhstan"
    }

    enum State {
        static let alabama = "Alabama"
        static let california = "California"
        static let northDakota = "North Dakota"
        static let southDakota = "South Dakota"
    }

    @discardableResult
    func launchWithoutTangemPay(
        geo: GeoState = .fullList,
        isRegionUnavailable: Bool = false,
        isBannerShown: Bool = false
    ) -> MainScreen {
        var scenarios = [
            ScenarioConfig(name: Constants.Scenario.kycStatus, initialState: Constants.ScenarioState.kycRequired),
            ScenarioConfig(name: Constants.Scenario.geo, initialState: geo.rawValue),
        ]
        if isRegionUnavailable {
            scenarios.append(ScenarioConfig(name: Constants.Scenario.eligibilityCheck, initialState: Constants.ScenarioState.unavailable))
        }
        if isBannerShown {
            scenarios.append(ScenarioConfig(name: Constants.Scenario.channels, initialState: Constants.ScenarioState.banner))
        }

        return launchAndImportHotWallet(
            eligibilityState: Constants.ScenarioState.notCustomer,
            scenarios: scenarios,
            featureToggles: Constants.marketingBannersShownWithSystemCards
        )
    }

    func openCountrySelection(from onboarding: TangemPayOnboardingScreen) -> TangemPayGeoSelectionScreen {
        let countrySelection = onboarding
            .waitForScreen()
            .tapGetCardExpectingCountrySelection()

        XCTContext.runActivity(named: "Make the wallet a Paera customer once the offer is accepted") { _ in
            wireMockClient.setScenarioStateSync(Constants.Scenario.eligibility, state: Constants.ScenarioState.paeraCustomer)
        }

        return countrySelection.waitForScreen(title: Localization.tangempayResidencyTitleCountry)
    }

    func openCountrySelectionFromDetails(_ details: DetailsScreen) -> TangemPayGeoSelectionScreen {
        openCountrySelection(from: details.verifyGetTangemPayVisible().openGetTangemPay())
    }

    func requestCount(_ endpoint: Endpoint, method: String = "GET") -> Int {
        wireMockRequestCount(method: method, urlPattern: endpoint.rawValue)
    }

    func verifyRequested(_ endpoint: Endpoint, method: String = "GET", since previousCount: Int) {
        waitForWireMockRequestCount(method: method, urlPattern: endpoint.rawValue, toExceed: previousCount)
    }

    func verifyNotRequested(_ endpoint: Endpoint, method: String = "GET", since previousCount: Int) {
        XCTContext.runActivity(named: "Verify \(method) \(endpoint.rawValue) was not requested") { _ in
            XCTAssertEqual(requestCount(endpoint, method: method), previousCount, "\(endpoint.rawValue) should not be requested yet")
        }
    }

    func verifyRequestedInOrder(_ first: Endpoint, then second: Endpoint, method: String = "GET") {
        XCTContext.runActivity(named: "Verify \(second.rawValue) was requested after \(first.rawValue)") { _ in
            let firstRequested = wireMockClient.findRequestTimestampsSync(method: method, urlPattern: first.rawValue).max()
            let secondRequested = wireMockClient.findRequestTimestampsSync(method: method, urlPattern: second.rawValue).max()

            guard let firstRequested, let secondRequested else {
                XCTFail("Both \(first.rawValue) and \(second.rawValue) should be requested")
                return
            }

            XCTAssertLessThan(firstRequested, secondRequested, "\(second.rawValue) should be requested after \(first.rawValue)")
        }
    }

    func waitlistRequestCount() -> Int {
        waitlistRequestBodies().count
    }

    func verifyWaitlistJoined(with expected: TangemPayWaitlistRequest, since previousCount: Int) {
        XCTContext.runActivity(named: "Verify the waitlist request \(expected) was sent") { _ in
            let bodies = waitlistRequestBodies()
            XCTAssertEqual(bodies.count, previousCount + 1, "Exactly one waitlist request should be sent")

            let request = bodies.last.flatMap(TangemPayWaitlistRequest.init(body:))
            XCTAssertNotNil(request, "Waitlist request body should be decodable: \(bodies.last ?? "none")")
            XCTAssertEqual(request, expected, "Waitlist request body should match")
        }
    }

    private func waitlistRequestBodies() -> [String] {
        wireMockClient.findRequestBodiesSync(method: "POST", urlPath: Endpoint.waitlist.rawValue)
    }
}

private extension TangemPayResidencyUITestCase {
    enum Constants {
        static let marketingBannersShownWithSystemCards = ["TWI-1841_hide_marketing_banners_while_system": false]

        enum Scenario {
            static let eligibility = "tangem_pay_eligibility"
            static let kycStatus = "tangem_pay_kyc_status"
            static let geo = "tangem_pay_geo_countries"
            static let eligibilityCheck = "tangem_pay_eligibility_check"
            static let channels = "tangem_pay_eligibility_channels"
        }

        enum ScenarioState {
            static let notCustomer = "Started"
            static let paeraCustomer = "PaeraCustomer"
            static let kycRequired = "Required"
            static let unavailable = "Unavailable"
            static let banner = "Banner"
        }
    }
}
