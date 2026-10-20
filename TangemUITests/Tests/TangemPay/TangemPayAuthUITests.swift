//
//  TangemPayAuthUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TangemPayAuthUITests: BaseTestCase {
    func testExistingUserAuthorization_ShowsTangemPayTileOnMain() {
        setAllureId(9630)

        launchAndImportHotWallet()
            .verifyTangemPayTileExists()
    }

    func testExpiredAccessTokenInBackground_RefreshesOnForeground() {
        setAllureId(9561)
        wireMockClient.resetRequestJournalSync()

        let mainScreen = launchAndImportHotWalletWithRealPayAuthorization(scenarios: [
            ScenarioConfig(name: Constants.Scenario.authToken, initialState: Constants.State.shortLivedAccessToken),
            ScenarioConfig(name: Constants.Scenario.balance, initialState: Constants.State.initialBalance),
        ])
        let sessionRenewedAt = Date()

        mainScreen.verifyTangemPayTileBalanceContains(Constants.initialBalance)

        XCTContext.runActivity(named: "Verify the access token was not refreshed before going to background") { _ in
            XCTAssertTrue(refreshTokenRequestBodies().isEmpty, "A fresh access token should not be refreshed yet")
        }

        minimizeApp()
        wireMockClient.setScenarioStateSync(Constants.Scenario.balance, state: Constants.State.afterTransaction)
        waitForAccessTokenExpiry(issuedBefore: sessionRenewedAt)
        maximizeApp()

        mainScreen
            .verifyTangemPayTileBalanceContains(Constants.updatedBalance)
            .openTangemPay()
            .waitForScreen()
            .verifyBalanceContains(Constants.updatedBalance)
            .verifySessionExpiredBannerHidden()

        XCTContext.runActivity(named: "Verify the access token was refreshed with the refresh token") { _ in
            let bodies = refreshTokenRequestBodies()
            XCTAssertFalse(bodies.isEmpty, "Returning to foreground with an expired access token should call the token refresh")
            XCTAssertTrue(
                bodies.allSatisfy { $0.contains(Constants.refreshToken) },
                "Token refresh should send the stored refresh token. Actual bodies: \(bodies)"
            )
        }
    }

    func testRenewSessionFailsWhenChallengeRequestFails() {
        setAllureId(9506)
        wireMockClient.resetRequestJournalSync()

        let mainScreen = launchAndImportHotWalletRequiringPayRenewal(scenarios: [
            ScenarioConfig(name: Constants.Scenario.authChallenge, initialState: Constants.State.error),
        ])
        .verifySessionExpiredBanner()
        .tapRenewSession()

        waitForRequest(to: Constants.Endpoint.challenge)
        mainScreen.verifyRenewSessionAvailableAfterFailure()

        XCTContext.runActivity(named: "Verify the token was not requested after the challenge failed") { _ in
            XCTAssertEqual(requestCount(to: Constants.Endpoint.token), 0, "A failed challenge should stop the authorization before the token request")
        }

        wireMockClient.resetScenarioSync(Constants.Scenario.authChallenge)
        mainScreen.renewTangemPaySession()
    }

    func testRenewSessionFailsWhenTokenRequestFails() {
        setAllureId(9508)
        wireMockClient.resetRequestJournalSync()

        let mainScreen = launchAndImportHotWalletRequiringPayRenewal(scenarios: [
            ScenarioConfig(name: Constants.Scenario.authToken, initialState: Constants.State.invalidSignature),
        ])
        .verifySessionExpiredBanner()
        .tapRenewSession()

        waitForRequest(to: Constants.Endpoint.challenge)
        waitForRequest(to: Constants.Endpoint.token)
        mainScreen.verifyRenewSessionAvailableAfterFailure()

        wireMockClient.resetScenarioSync(Constants.Scenario.authToken)
        mainScreen.renewTangemPaySession()
    }

    private func waitForRequest(to urlPath: String) {
        XCTContext.runActivity(named: "Wait for the POST \(urlPath) request") { _ in
            let predicate = NSPredicate { [self] _, _ in requestCount(to: urlPath) > 0 }
            let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
            XCTAssertEqual(
                XCTWaiter().wait(for: [expectation], timeout: .networkRequest),
                .completed,
                "Renew session should send POST \(urlPath)"
            )
        }
    }

    private func requestCount(to urlPath: String) -> Int {
        wireMockClient.requestCountSync(method: "POST", urlPathPattern: urlPath)
    }

    private func waitForAccessTokenExpiry(issuedBefore date: Date) {
        XCTContext.runActivity(named: "Wait in background until the access token expires") { _ in
            let expiry = date.addingTimeInterval(Constants.accessTokenLifetime + Constants.clockSkewMargin)
            let expectation = XCTNSPredicateExpectation(
                predicate: NSPredicate { _, _ in Date() >= expiry },
                object: nil
            )
            let result = XCTWaiter().wait(for: [expectation], timeout: expiry.timeIntervalSinceNow + .conditional)
            XCTAssertEqual(result, .completed, "The access token lifetime should run out while the app is in background")
        }
    }

    private func refreshTokenRequestBodies() -> [String] {
        wireMockClient.findRequestBodiesSync(method: "POST", urlPath: Constants.Endpoint.refreshToken)
    }
}

private extension TangemPayAuthUITests {
    enum Constants {
        static let initialBalance = "$10.00"
        static let updatedBalance = "$9.00"
        static let refreshToken = "mock-refresh-token"
        static let accessTokenLifetime: TimeInterval = 60
        static let clockSkewMargin: TimeInterval = 15

        enum Scenario {
            static let authToken = "tangem_pay_auth_token"
            static let authChallenge = "tangem_pay_auth_challenge"
            static let balance = "tangem_pay_balance_update"
        }

        enum State {
            static let shortLivedAccessToken = "ShortLivedAccessToken"
            static let initialBalance = "InitialBalance"
            static let afterTransaction = "AfterTransaction"
            static let error = "Error"
            static let invalidSignature = "InvalidSignature"
        }

        enum Endpoint {
            static let refreshToken = "/auth/token/refresh"
            static let challenge = "/auth/challenge"
            static let token = "/auth/token"
        }
    }
}
