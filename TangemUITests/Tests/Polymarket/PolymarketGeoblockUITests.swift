//
//  PolymarketGeoblockUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class PolymarketGeoblockUITests: PolymarketUITestCase {
    func testPolymarket_regionBlockedNewAccountShowsRegionRestrictions() {
        setAllureId(12903)
        let deployRequestsBefore = polymarketRequestCount(method: "POST", path: Constants.Path.deploy)

        launchPolymarketWithHotWallet(scenarios: [geoblockScenario(Constants.State.blocked)])
            .openMarketsSheet()
            .openPolymarket()
            .waitForWelcome()
            .confirmOnboardingExpectingRegionRestrictions()
            .waitForSheet()

        XCTAssertEqual(polymarketRequestCount(method: "POST", path: Constants.Path.deploy), deployRequestsBefore)
    }

    func testPolymarket_regionBlockedReadyAccountReconnectsThenShowsBanner() {
        setAllureId(13356)
        let scenarios = [geoblockScenario(Constants.State.blocked)] + walletScenarios(Constants.State.readyToTrade)

        launchPolymarketWithHotWallet(scenarios: scenarios)
            .openMarketsSheet()
            .openPolymarket()
            .waitForReconnect()

        PolymarketRegionRestrictionsSheet(app)
            .verifyNotDisplayed()
        PolymarketOnboardingScreen(app)
            .confirmOnboarding()
            .waitForScreen()
            .verifyRegionBannerDisplayed()
    }

    func testPolymarket_noRestrictionsOpenTheAccountWithFullAccess() {
        setAllureId(12929)
        let geoblockRequestsBefore = polymarketRequestCount(method: "GET", path: Constants.Path.geoblock)
        let depositRequestsBefore = polymarketRequestCount(method: "POST", path: Constants.Path.bridgeDeposit)

        let mainScreen = launchPolymarketWithHotWallet(scenarios: polymarketFullAccessScenarios())
            .openMarketsSheet()
            .openPolymarket()
            .waitForWelcome()
            .confirmOnboarding()
            .waitForScreen()
            .closeOnboardingStoriesIfDisplayed()

        waitForPolymarketRequestCount(method: "GET", path: Constants.Path.geoblock, toExceed: geoblockRequestsBefore)
        waitForPolymarketRequestCount(method: "POST", path: Constants.Path.bridgeDeposit, toExceed: depositRequestsBefore)

        let positionScreen = mainScreen
            .verifyRegionBannerNotDisplayed()
            .verifyAvailableBalanceDisplayed()
            .verifyWithdrawEnabled()
            .verifyActivePositionsDisplayed()
            .openHistory()
            .waitForScreen()
            .goBack()
            .waitForScreen()
            .openAddFunds()
            .verifyOptionsDisplayed()
            .close()
            .waitForScreen()
            .openFirstPosition()
            .verifyBuyEnabled()

        positionScreen
            .tapBuy()
            .waitForSheet()
            .close(returningTo: PolymarketPositionDetailsScreen.self)
            .verifyBuyDisplayed()
            .tapCashOut()
            .waitForSheet()
            .close(returningTo: PolymarketPositionDetailsScreen.self)
            .goBack()
            .waitForScreen()
            .openRedeemablePosition()
            .verifyClaimRewardDisplayed()
            .close()
            .waitForScreen()
            .tapWithdraw()
            .waitForScreen()
            .close()
            .waitForScreen()
            .openFirstOutcome()
            .waitForSheet()
    }

    func testPolymarket_restrictedRegionOpensTheAccountInReadOnlyMode() {
        setAllureId(12930)

        let mainScreen = launchPolymarketWithHotWallet(scenarios: polymarketFullAccessScenarios())
            .openMarketsSheet()
            .openPolymarket()
            .waitForWelcome()
            .confirmOnboarding()
            .waitForScreen()
            .closeOnboardingStoriesIfDisplayed()
            .goBack()

        wireMockClient.setScenarioStateSync(Constants.Scenario.geoblock, state: Constants.State.blocked)

        let restrictedMainScreen = mainScreen
            .openMarketsSheet()
            .openPolymarketAccount()
            .waitForScreen()

        PolymarketRegionRestrictionsSheet(app)
            .waitForSheet()
            .close(returningTo: PolymarketMainScreen.self)
            .verifyRegionBannerDisplayed()
            .verifyAvailableBalanceDisplayed()
            .verifyWithdrawEnabled()
            .verifyActivePositionsDisplayed()
            .openHistory()
            .waitForScreen()
            .goBack()
            .waitForScreen()

        let geoblockRequestsBeforeActions = polymarketRequestCount(method: "GET", path: Constants.Path.geoblock)

        restrictedMainScreen
            .openRegionRestrictionsFromAddFunds()
            .waitForSheet()
            .close(returningTo: PolymarketAddFundsSheet.self)
            .verifyOptionsNotDisplayed()

        restrictedMainScreen
            .tapWithdraw()
            .waitForScreen()
        PolymarketRegionRestrictionsSheet(app)
            .verifyNotDisplayed()
        PolymarketWithdrawScreen(app)
            .close()
            .waitForScreen()
            .openFirstPosition()
            .verifyBuyEnabled()
            .tapBuy()
        PolymarketRegionRestrictionsSheet(app)
            .waitForSheet()
            .close(returningTo: PolymarketOrderSheet.self)
            .verifyNotDisplayed()
        PolymarketPositionDetailsScreen(app)
            .verifyBuyDisplayed()
            .tapCashOut()
        PolymarketRegionRestrictionsSheet(app)
            .waitForSheet()
            .close(returningTo: PolymarketOrderSheet.self)
            .verifyNotDisplayed()
        PolymarketPositionDetailsScreen(app)
            .goBack()
            .waitForScreen()
            .openRedeemablePosition()
            .tapClaimReward()
        PolymarketRegionRestrictionsSheet(app)
            .verifyNotDisplayed()
        PolymarketRedeemSheet(app)
            .close()
            .waitForScreen()
            .verifyFirstOutcomeDisplayed()

        XCTAssertEqual(
            polymarketRequestCount(method: "GET", path: Constants.Path.geoblock),
            geoblockRequestsBeforeActions,
            "No new geoblock request should be sent while the restricted state is known"
        )
    }

    private func geoblockScenario(_ state: String) -> ScenarioConfig {
        ScenarioConfig(name: Constants.Scenario.geoblock, initialState: state)
    }

    private func walletScenarios(_ state: String) -> [ScenarioConfig] {
        [
            ScenarioConfig(name: Constants.Scenario.wallet, initialState: state),
            ScenarioConfig(name: Constants.Scenario.ownerWallet, initialState: state),
        ]
    }
}

private extension PolymarketGeoblockUITests {
    typealias Constants = PolymarketUITestsConstants
}
