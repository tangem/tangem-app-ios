//
//  TangemPayBalanceSyncUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TangemPayBalanceSyncUITests: BaseTestCase {
    private static let balanceEndpointPattern = "/bff-v2/v1/customer/balance"
    private static let customerInfoEndpointPattern = "/bff-v2/v1/customer/me"

    func testBalanceRefreshesViaPullToRefresh_AndSyncsToMain() {
        setAllureId(9529)

        let tangemPayScreen = launchAndImportHotWallet(
            scenarios: [ScenarioConfig(name: "tangem_pay_balance_update", initialState: "InitialBalance")]
        )
        .openTangemPay()
        .waitForScreen()
        .verifyBalanceContains("$10.00")

        wireMockClient.setScenarioStateSync("tangem_pay_balance_update", state: "AfterTransaction")

        let before = balanceRequestCount()
        pullToRefresh()
        tangemPayScreen.verifyBalanceContains("$9.00")

        XCTContext.runActivity(named: "Verify /customer/balance was requested on pull-to-refresh") { _ in
            let after = balanceRequestCount()
            XCTAssertGreaterThan(after, before, "Pull-to-refresh should request /customer/balance")
        }

        tangemPayScreen
            .tapBack()
            .verifyTangemPayTileBalanceContains("$9.00")
    }

    func testBalanceUpdatesOnExitFromCardDetails() {
        setAllureId(9549)

        let tangemPayScreen = launchAndImportHotWallet(
            scenarios: [ScenarioConfig(name: "tangem_pay_balance_update", initialState: "InitialBalance")]
        )
        .openTangemPay()
        .waitForScreen()
        .verifyBalanceContains("$10.00")

        wireMockClient.setScenarioStateSync("tangem_pay_balance_update", state: "AfterTransaction")
        let before = customerInfoRequestCount()

        tangemPayScreen
            .tapBack()
            .verifyTangemPayTileBalanceContains("$9.00")

        XCTContext.runActivity(named: "Verify customer/me was requested on exit from card details") { _ in
            let after = customerInfoRequestCount()
            XCTAssertGreaterThan(after, before, "Leaving card details should request customer/me")
        }
    }

    func testBalanceStaysInSyncBetweenDetailsAndMain() {
        setAllureId(9550)

        let tangemPayScreen = launchAndImportHotWallet(
            scenarios: [ScenarioConfig(name: "tangem_pay_balance_update", initialState: "InitialBalance")]
        )
        .openTangemPay()
        .waitForScreen()
        .verifyBalanceContains("$10.00")

        wireMockClient.setScenarioStateSync("tangem_pay_balance_update", state: "AfterTransaction")
        pullToRefresh()

        tangemPayScreen
            .verifyBalanceContains("$9.00")
            .tapBack()
            .verifyTangemPayTileBalanceContains("$9.00")
            .openTangemPay()
            .waitForScreen()
            .verifyBalanceContains("$9.00")
    }

    private func balanceRequestCount() -> Int {
        wireMockClient.requestCountSync(method: "GET", urlPathPattern: Self.balanceEndpointPattern)
    }

    private func customerInfoRequestCount() -> Int {
        wireMockClient.requestCountSync(method: "GET", urlPathPattern: Self.customerInfoEndpointPattern)
    }
}
