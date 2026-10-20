//
//  StakingEthP2PVaultLimitUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class StakingEthP2PVaultLimitUITests: BaseTestCase {
    func testStakingUnavailableWhenVaultLimitReached() {
        setAllureId(11513)

        let balancesRequestsBefore = p2pBalancesRequestCount()

        launchApp(
            tangemApiType: .mock,
            stakingApiType: .mock,
            clearStorage: true,
            scenarios: scenarios(capacityState: Constants.State.full)
        )

        let importedMainScreen = importHotWallet()

        waitUntil("P2P balances are requested after the vaults are loaded") {
            self.p2pBalancesRequestCount() > balancesRequestsBefore
        }

        importedMainScreen
            .waitForTokenRow(Constants.tokenName)
            .waitForTokenBalanceLoaded(tokenName: Constants.tokenName)
            .assertEarnBadgeNotDisplayed(tokenName: Constants.tokenName)
            .tapToken(Constants.tokenName)
            .waitForNonZeroTotalBalance()
            .assertNativeStakingBlockNotDisplayed()

        app.terminate()

        launchApp(
            tangemApiType: .mock,
            stakingApiType: .mock,
            keepWallets: true,
            scenarios: scenarios(capacityState: Constants.State.available)
        )

        MainScreen(app)
            .waitForTokenRow(Constants.tokenName)
            .assertEarnBadgeDisplayed(tokenName: Constants.tokenName)
            .tapToken(Constants.tokenName)
            .waitForNonZeroTotalBalance()
            .assertNativeStakingBlockTitle(Localization.tokenDetailsStakingBlockTitle)
    }

    private func p2pBalancesRequestCount() -> Int {
        wireMockClient.requestCountSync(method: Constants.Endpoint.method, urlPathPattern: Constants.Endpoint.balances)
    }

    private func waitUntil(_ description: String, timeout: TimeInterval = .networkRequest, _ condition: @escaping () -> Bool) {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in condition() }, object: nil)
        XCTAssertEqual(XCTWaiter().wait(for: [expectation], timeout: timeout), .completed, "Timed out waiting: \(description)")
    }

    private func scenarios(capacityState: String) -> [ScenarioConfig] {
        [
            ScenarioConfig(name: Constants.Scenario.portfolio, initialState: Constants.State.hotWalletPortfolio),
            ScenarioConfig(name: Constants.Scenario.vaultCapacity, initialState: capacityState),
        ]
    }
}

private extension StakingEthP2PVaultLimitUITests {
    enum Constants {
        static let tokenName = "Ethereum"

        enum Endpoint {
            static let method = "POST"
            static let balances = "/p2p_api/api/v1/staking/pool/mainnet/vaults/.*/accounts/list"
        }

        enum Scenario {
            static let portfolio = "user_tokens_api"
            static let vaultCapacity = "p2p_eth_pool_capacity"
        }

        enum State {
            static let hotWalletPortfolio = "HotWalletSvS"
            static let full = "Full"
            static let available = "Available"
        }
    }
}
