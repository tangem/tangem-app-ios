//
//  YieldModeUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class YieldModeUITests: BaseTestCase {
    func testFirstTimeLandingActivationWithZeroBalance() {
        setAllureId(7957)

        let tokenScreen = launchAndOpenYieldToken(
            portfolio: Constants.portfolioZeroBalance,
            balances: Constants.balancesZeroUsdc,
            yield: Constants.yieldNotActive
        )

        tokenScreen
            .waitForAvailableYieldBlock()
            .tapAvailableYieldBlock()
            .tapContinue()
            .holdToStartEarning()

        wireMockClient.setScenarioStateSync(Constants.yieldScenario, state: Constants.yieldActive)

        tokenScreen
            .waitForYieldEnabledBlock()
            .assertYieldApyDisplayed()
    }

    func testFirstTimeLandingActivation() {
        setAllureId(4938)

        let tokenScreen = launchAndOpenYieldToken(
            portfolio: Constants.portfolioYieldUsdc,
            balances: Constants.balancesNonZero,
            yield: Constants.yieldNotActive
        )

        tokenScreen
            .waitForAvailableYieldBlock()
            .tapAvailableYieldBlock()
            .tapContinue()
            .holdToStartEarning()

        wireMockClient.setScenarioStateSync(Constants.yieldScenario, state: Constants.yieldActive)
        pullToRefresh()

        tokenScreen
            .waitForYieldEnabledBlock()
            .assertYieldApyDisplayed()
    }

    func testTopUpForActiveLanding() {
        setAllureId(5473)

        let tokenScreen = launchAndOpenYieldToken(
            portfolio: Constants.portfolioYieldUsdc,
            balances: Constants.balancesNonZero,
            yield: Constants.yieldTopUp
        )

        tokenScreen
            .assertYieldInfoIconVisible()
            .waitForTransaction(key: Constants.txReceived)

        tokenScreen
            .tapYieldEnabledBlock()
            .assertNotificationTitle(contains: Constants.usdc)
    }

    func testGrantApproval() {
        setAllureId(7960)

        let tokenScreen = launchAndOpenYieldToken(
            portfolio: Constants.portfolioYieldUsdc,
            balances: Constants.balancesNonZero,
            yield: Constants.yieldActive
        )

        tokenScreen
            .assertYieldInfoIconVisible()
            .tapYieldEnabledBlock()
            .assertNotificationDisplayed()
            .tapApprove()
            .holdToConfirm()

        wireMockClient.setScenarioStateSync(Constants.yieldScenario, state: Constants.yieldApproveGranted)
        pullToRefresh()

        tokenScreen.assertYieldInfoIconHidden()
    }

    func testReopenLandingActivation() {
        setAllureId(4940)

        let tokenScreen = launchAndOpenYieldToken(
            portfolio: Constants.portfolioYieldUsdc,
            balances: Constants.balancesNonZero,
            yield: Constants.yieldNotActive
        )

        tokenScreen
            .waitForAvailableYieldBlock()
            .tapAvailableYieldBlock()
            .tapContinue()
            .holdToStartEarning()

        wireMockClient.setScenarioStateSync(Constants.yieldScenario, state: Constants.yieldActive)
        pullToRefresh()

        tokenScreen
            .waitForYieldEnabledBlock()
            .assertYieldApyDisplayed()

        tokenScreen
            .goBackToMain()
            .tapToken(Constants.usdc)
            .waitForYieldEnabledBlock()
            .assertYieldApyDisplayed()
    }

    func testCloseActiveLanding() {
        setAllureId(4937)

        let tokenScreen = launchAndOpenYieldToken(
            portfolio: Constants.portfolioYieldUsdc,
            balances: Constants.balancesNonZero,
            yield: Constants.yieldActive
        )

        tokenScreen
            .waitForYieldEnabledBlock()
            .tapYieldEnabledBlock()
            .tapDisableYieldMode()
            .holdToConfirm()

        wireMockClient.setScenarioStateSync(Constants.yieldScenario, state: Constants.yieldExited)

        tokenScreen.waitForAvailableYieldBlock()
    }

    private func launchAndOpenYieldToken(portfolio: String, balances: String, yield: String) -> TokenScreen {
        launchApp(
            tangemApiType: .mock,
            expressApiType: .mock,
            yieldApiType: .mock,
            clearStorage: true,
            features: [.redesign: true, .yieldModuleUpdate: true],
            scenarios: [
                ScenarioConfig(name: Constants.portfolioScenario, initialState: portfolio),
                ScenarioConfig(name: Constants.balancesScenario, initialState: balances),
                ScenarioConfig(name: Constants.yieldScenario, initialState: yield),
            ]
        )

        let tokenScreen = importHotWallet().tapToken(Constants.usdc)
        // The available yield block renders only once markets data is loaded; refresh to force it on slow CI.
        pullToRefresh()
        return tokenScreen
    }

    private enum Constants {
        static let usdc = "USDC"

        static let portfolioScenario = "user_tokens_api"
        static let portfolioYieldUsdc = "YieldUSDCEthereum"
        static let portfolioZeroBalance = "YieldUSDCEthereumZeroBalance"

        static let balancesScenario = "moralis_evm_token_balances_api"
        static let balancesNonZero = "NonZeroEvmBalances"
        static let balancesZeroUsdc = "ZeroUsdcEvmBalances"

        static let yieldScenario = "yield_supply_status"
        static let yieldNotActive = "NotActive"
        static let yieldActive = "Active"
        static let yieldTopUp = "TopUp"
        static let yieldApproveGranted = "ApproveGranted"
        static let yieldExited = "Exited"

        static let txReceived = "transfer"
    }
}
