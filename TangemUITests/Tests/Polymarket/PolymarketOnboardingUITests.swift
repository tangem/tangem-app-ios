//
//  PolymarketOnboardingUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class PolymarketOnboardingUITests: PolymarketUITestCase {
    func testPolymarket_completedOnboardingShowsStoriesAndOpensTheAccount() {
        setAllureId(12918)

        launchPolymarketWithHotWallet()
            .openMarketsSheet()
            .openPolymarket()
            .waitForWelcome()
            .confirmOnboardingExpectingStories()
            .waitForStories()
            .close()
            .waitForScreen()
    }

    func testPolymarket_accountStatusRequestedByWalletIdThenByOwnerAddress() {
        setAllureId(12899)
        let byWalletIdBefore = polymarketWalletStatusQueryValues(named: Constants.Query.walletId).count

        let mainScreen = launchPolymarketWithHotWallet()
        waitForPolymarketWalletStatusQuery(named: Constants.Query.walletId, toExceed: byWalletIdBefore)
        let byOwnerBefore = polymarketWalletStatusQueryValues(named: Constants.Query.ownerAddress).count
        XCTAssertTrue(
            polymarketWalletStatusQueryValues(named: Constants.Query.walletId)
                .dropFirst(byWalletIdBefore)
                .contains(Constants.Wallet.walletId),
            "The status should be requested by the hot wallet id"
        )

        let welcomeScreen = mainScreen
            .openMarketsSheet()
            .openPolymarket()
            .waitForWelcome()

        XCTAssertEqual(
            polymarketWalletStatusQueryValues(named: Constants.Query.ownerAddress).count,
            byOwnerBefore,
            "The status should not be requested by owner address before onboarding starts"
        )

        welcomeScreen
            .confirmOnboarding()
            .waitForScreen()

        waitForPolymarketWalletStatusQuery(named: Constants.Query.ownerAddress, toExceed: byOwnerBefore)
    }

    func testPolymarket_depositWalletDeployedWithWalletOwnAddresses() {
        setAllureId(12910)
        let deployRequestsBefore = polymarketRequestCount(method: "POST", path: Constants.Path.deploy)

        completeOnboarding()

        assertPolymarketDeployRequestMatchesWallet(requestsBefore: deployRequestsBefore)
    }

    func testPolymarket_l2CredentialsCreatedWhenTheyCannotBeDerived() {
        setAllureId(12913)
        let deployRequestsBefore = polymarketRequestCount(method: "POST", path: Constants.Path.deploy)
        let deriveRequestsBefore = polymarketRequestCount(method: "GET", path: Constants.Path.deriveKey)
        let createRequestsBefore = polymarketRequestCount(method: "POST", path: Constants.Path.createKey)

        completeOnboarding(scenarios: [credentialsScenario(Constants.State.notExisting)])

        XCTAssertGreaterThan(polymarketRequestCount(method: "GET", path: Constants.Path.deriveKey), deriveRequestsBefore)
        XCTAssertEqual(polymarketRequestCount(method: "POST", path: Constants.Path.createKey), createRequestsBefore + 1)
        assertPolymarketRequestOrder(
            first: ("POST", Constants.Path.deploy, deployRequestsBefore),
            second: ("GET", Constants.Path.deriveKey, deriveRequestsBefore)
        )
        assertPolymarketRequestOrder(
            first: ("GET", Constants.Path.deriveKey, deriveRequestsBefore),
            second: ("POST", Constants.Path.createKey, createRequestsBefore)
        )
        assertPolymarketL1HeadersSent(method: "GET", path: Constants.Path.deriveKey, requestsBefore: deriveRequestsBefore)
        assertPolymarketL1HeadersSent(method: "POST", path: Constants.Path.createKey, requestsBefore: createRequestsBefore)
        assertPolymarketL2CredentialsSent(apiKey: Constants.Wallet.createdApiKey)
    }

    func testPolymarket_reconnectWithoutL2CredentialsThenStraightToAccount() {
        setAllureId(12904)
        let deployRequestsBefore = polymarketRequestCount(method: "POST", path: Constants.Path.deploy)
        let approvalsRequestsBefore = polymarketRequestCount(method: "POST", path: Constants.Path.approvals)
        let createRequestsBefore = polymarketRequestCount(method: "POST", path: Constants.Path.createKey)

        let reconnectedScreen = launchPolymarketWithHotWallet(scenarios: walletScenarios(Constants.State.readyToTrade))
            .openMarketsSheet()
            .openPolymarket()
            .waitForReconnect()
            .confirmOnboarding()
            .waitForScreen()

        PolymarketStoriesScreen(app)
            .verifyNotDisplayed()
        let mainScreen = reconnectedScreen.goBack()

        XCTAssertEqual(polymarketRequestCount(method: "POST", path: Constants.Path.createKey), createRequestsBefore)

        let deriveRequestsAfterReconnect = polymarketRequestCount(method: "GET", path: Constants.Path.deriveKey)
        let balanceRequestsAfterReconnect = polymarketRequestCount(method: "GET", path: Constants.Path.balance)

        let reopenedScreen = mainScreen
            .openMarketsSheet()
            .openPolymarketAccount()
            .waitForScreen()

        PolymarketOnboardingScreen(app)
            .verifyWelcomeNotDisplayed()
        PolymarketStoriesScreen(app)
            .verifyNotDisplayed()
        assertPolymarketL2CredentialsSent(apiKey: Constants.Wallet.derivedApiKey, balanceRequestsBefore: balanceRequestsAfterReconnect)
        XCTAssertEqual(polymarketRequestCount(method: "GET", path: Constants.Path.deriveKey), deriveRequestsAfterReconnect)
        XCTAssertEqual(polymarketRequestCount(method: "POST", path: Constants.Path.deploy), deployRequestsBefore)
        XCTAssertEqual(polymarketRequestCount(method: "POST", path: Constants.Path.approvals), approvalsRequestsBefore)

        wireMockClient.setScenarioStateSync(Constants.Scenario.balance, state: Constants.State.expired)

        reopenedScreen
            .goBack()
            .openMarketsSheet()
            .openPolymarket()
            .waitForReconnect()
    }

    func testPolymarket_deployedStatusSkipsDeploy() {
        setAllureId(13353)
        let deployRequestsBefore = polymarketRequestCount(method: "POST", path: Constants.Path.deploy)
        let approvalsRequestsBefore = polymarketRequestCount(method: "POST", path: Constants.Path.approvals)

        completeOnboarding(scenarios: walletScenarios(Constants.State.deployed))

        XCTAssertEqual(polymarketRequestCount(method: "POST", path: Constants.Path.deploy), deployRequestsBefore)
        XCTAssertEqual(polymarketRequestCount(method: "POST", path: Constants.Path.approvals), approvalsRequestsBefore + 1)
        assertPolymarketApprovalsRequestMatchesWallet(requestsBefore: approvalsRequestsBefore)
    }

    func testPolymarket_deploymentInProgressPollsStatusUntilFinal() {
        setAllureId(13354)
        let deployRequestsBefore = polymarketRequestCount(method: "POST", path: Constants.Path.deploy)
        let ownerStatusRequestsBefore = polymarketWalletStatusQueryValues(named: Constants.Query.ownerAddress).count
        let approvalsRequestsBefore = polymarketRequestCount(method: "POST", path: Constants.Path.approvals)

        completeOnboarding(scenarios: walletScenarios(Constants.State.deploymentInProgress))

        XCTAssertEqual(polymarketRequestCount(method: "POST", path: Constants.Path.deploy), deployRequestsBefore)
        XCTAssertGreaterThanOrEqual(
            polymarketWalletStatusQueryValues(named: Constants.Query.ownerAddress).count,
            ownerStatusRequestsBefore + Constants.minimumStatusPolls
        )
        XCTAssertEqual(polymarketRequestCount(method: "POST", path: Constants.Path.approvals), approvalsRequestsBefore + 1)
    }

    func testPolymarket_failedDeploymentIsDeployedAgain() {
        setAllureId(13355)
        let deployRequestsBefore = polymarketRequestCount(method: "POST", path: Constants.Path.deploy)
        let approvalsRequestsBefore = polymarketRequestCount(method: "POST", path: Constants.Path.approvals)

        completeOnboarding(scenarios: walletScenarios(Constants.State.deploymentFailed))

        assertPolymarketDeployRequestMatchesWallet(requestsBefore: deployRequestsBefore)
        XCTAssertEqual(polymarketRequestCount(method: "POST", path: Constants.Path.approvals), approvalsRequestsBefore + 1)
    }

    func testPolymarket_accountStatusRequestedForEveryAddedWallet() {
        setAllureId(13417)
        let walletIdsBefore = polymarketWalletStatusQueryValues(named: Constants.Query.walletId)

        let mainScreen = launchPolymarketWithHotWallet()
        waitForPolymarketWalletStatusQuery(named: Constants.Query.walletId, toExceed: walletIdsBefore.count)
        XCTAssertTrue(
            polymarketWalletStatusQueryValues(named: Constants.Query.walletId)
                .dropFirst(walletIdsBefore.count)
                .contains(Constants.Wallet.walletId),
            "The status should be requested by the hot wallet id"
        )

        let requestsBeforeAdding = polymarketWalletStatusQueryValues(named: Constants.Query.walletId).count
        mainScreen.addNewWallet(name: .wallet2)

        waitForPolymarketWalletStatusQuery(named: Constants.Query.walletId, toExceed: requestsBeforeAdding)
        XCTAssertTrue(
            polymarketWalletStatusQueryValues(named: Constants.Query.walletId)
                .dropFirst(walletIdsBefore.count)
                .contains { $0 != Constants.Wallet.walletId },
            "The status should be requested by the id of the added wallet as well"
        )
    }

    private func completeOnboarding(scenarios: [ScenarioConfig] = []) {
        launchPolymarketWithHotWallet(scenarios: scenarios)
            .openMarketsSheet()
            .openPolymarket()
            .waitForWelcome()
            .confirmOnboarding()
            .waitForScreen()
    }

    private func walletScenarios(_ state: String) -> [ScenarioConfig] {
        [
            ScenarioConfig(name: Constants.Scenario.wallet, initialState: state),
            ScenarioConfig(name: Constants.Scenario.ownerWallet, initialState: state),
        ]
    }

    private func credentialsScenario(_ state: String) -> ScenarioConfig {
        ScenarioConfig(name: Constants.Scenario.credentials, initialState: state)
    }
}

private extension PolymarketOnboardingUITests {
    typealias Constants = PolymarketUITestsConstants
}
