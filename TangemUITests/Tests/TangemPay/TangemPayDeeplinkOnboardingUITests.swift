//
//  TangemPayDeeplinkOnboardingUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TangemPayDeeplinkOnboardingUITests: BaseTestCase {
    private let safariHelper = SafariHelper()

    func testOnboardingOpens_WhenOnboardVisaDeeplinkIsValid() {
        setAllureId(9527)

        launchAndImportHotWallet(eligibilityState: Constants.State.notPaeraCustomer)
            .verifyTokensListDisplayed()

        openFromSafari(Constants.Link.onboardVisa)

        TangemPayOnboardingScreen(app)
            .waitForScreen()

        verifyValidateRequested(with: Constants.Link.onboardVisa)
    }

    func testOnboardingDoesNotOpen_WhenOnboardVisaDeeplinkIsInvalid() {
        setAllureId(10415)

        let mainScreen = launchAndImportHotWallet(
            eligibilityState: Constants.State.notPaeraCustomer,
            scenarios: [ScenarioConfig(name: Constants.Scenario.validate, initialState: Constants.State.invalid)]
        )
        .verifyTokensListDisplayed()

        openFromSafari(Constants.Link.onboardVisa)

        TangemPayOnboardingScreen(app)
            .verifyNotDisplayed()

        verifyValidateRequested(with: Constants.Link.onboardVisa)

        mainScreen.verifyTokensListInteractive()
    }

    func testOnboardingDoesNotOpen_WhenDeeplinkReceivedWithoutWallet() {
        setAllureId(12096)

        launchWithoutWallet()

        openFromSafari(Constants.Link.onboardVisa)

        CreateWalletSelectorScreen(app)
            .waitForScreen()

        TangemPayOnboardingScreen(app)
            .verifyNotDisplayed()

        TangemPayMobileOnboardingScreen(app)
            .verifyNotDisplayed(for: .quick)

        CreateWalletSelectorScreen(app)
            .waitForScreen()

        verifyValidateNotRequested()
    }

    func testOnboardingOpens_WhenWalletCreatedAfterDeeplink() {
        setAllureId(12097)

        launchWithoutWallet()

        openFromSafari(Constants.Link.onboardVisa)

        CreateWalletSelectorScreen(app)
            .createMobileWallet()

        TangemPayOnboardingScreen(app)
            .waitForScreen()

        TangemPayMobileOnboardingScreen(app)
            .verifyNotDisplayed(for: .quick)

        verifyValidateRequested(with: Constants.Link.onboardVisa)
    }

    func testOnboardingOpensAndGetCardAsksForAuthorization_WhenPayAppLinkOpened() {
        setAllureId(9698)

        launchAndImportHotWallet(
            eligibilityState: Constants.State.notPaeraCustomer,
            accessCode: Constants.accessCode
        )
        .verifyTokensListDisplayed()

        openFromSafari(Constants.Link.payApp)

        TangemPayOnboardingScreen(app)
            .waitForScreen()
            .tapGetCardExpectingUnlock()
            .waitForScreen()
    }

    private func launchWithoutWallet() {
        launchApp(
            tangemApiType: .mock,
            visaApiType: .mock,
            clearStorage: true,
            scenarios: [ScenarioConfig(name: Constants.Scenario.eligibility, initialState: Constants.State.notPaeraCustomer)]
        )
    }

    private func openFromSafari(_ link: String) {
        XCTContext.runActivity(named: "Open \(link) from Safari") { _ in
            wireMockClient.resetRequestJournalSync()
            safariHelper.safari.launch()
            safariHelper.openDeeplink(link)
            safariHelper.tapOpenButton()
        }
    }

    private func verifyValidateRequested(with link: String) {
        XCTContext.runActivity(named: "Verify deeplink validation was requested once for \(link)") { _ in
            XCTAssertEqual(validateRequestLinks(), [link], "Deeplink validation should be requested once with the opened link")
        }
    }

    private func verifyValidateNotRequested() {
        XCTContext.runActivity(named: "Verify deeplink validation was not requested") { _ in
            XCTAssertTrue(validateRequestLinks().isEmpty, "Deeplink validation should not be requested")
        }
    }

    private func validateRequestLinks() -> [String] {
        wireMockClient
            .findRequestBodiesSync(method: "POST", urlPath: Constants.Endpoint.validate)
            .map { body in
                let payload = try? JSONDecoder().decode([String: String].self, from: Data(body.utf8))
                return payload?[Constants.linkKey] ?? body
            }
    }
}

private extension TangemPayDeeplinkOnboardingUITests {
    enum Constants {
        static let accessCode = "141261"
        static let linkKey = "link"

        enum Scenario {
            static let eligibility = "tangem_pay_eligibility"
            static let validate = "tangem_pay_deeplink_validate"
        }

        enum State {
            static let notPaeraCustomer = "Started"
            static let invalid = "Invalid"
        }

        enum Endpoint {
            static let validate = "/bff-v2/v1/deeplink/validate"
        }

        enum Link {
            static let onboardVisa = "tangem://onboard-visa?entry=ff1&id=6USB3LU2"
            static let payApp = "tangem://pay-app?id=dec25"
        }
    }
}
