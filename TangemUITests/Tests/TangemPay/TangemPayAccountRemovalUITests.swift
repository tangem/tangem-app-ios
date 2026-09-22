//
//  TangemPayAccountRemovalUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TangemPayAccountRemovalUITests: BaseTestCase {
    private static let removalScenario = "tangem_pay_account_removal"
    private static let deactivatedState = "Deactivated"
    private static let payEnabledEndpoint = "/bff-v2/v1/customer/pay-enabled"

    func testRemoveAccountFromActionsMenu() {
        setAllureId(10418)

        let paymentAccount = openDeactivatedPaymentAccount()
        let requestsBeforeRemoval = payEnabledRequestCount()

        paymentAccount
            .openRemoveAccountFromMoreActions()
            .verifyRemoveAccountAlert()
            .confirmRemoveAccount()
            .verifyTangemPayTileNotVisible()

        verifyPayEnabledCalled(requestsBeforeRemoval: requestsBeforeRemoval)

        relaunchKeepingState()
            .verifyTangemPayTileNotVisible()
    }

    func testRemoveAccountFromDeactivatedBanner() {
        setAllureId(10419)

        let paymentAccount = openDeactivatedPaymentAccount()
        let requestsBeforeRemoval = payEnabledRequestCount()

        paymentAccount
            .tapRemoveAccountOnBanner()
            .verifyRemoveAccountAlert()
            .confirmRemoveAccount()
            .verifyTangemPayTileNotVisible()

        verifyPayEnabledCalled(requestsBeforeRemoval: requestsBeforeRemoval)

        relaunchKeepingState()
            .verifyTangemPayTileNotVisible()
    }

    private func openDeactivatedPaymentAccount() -> TangemPayMainScreen {
        launchAndImportHotWallet(
            scenarios: [ScenarioConfig(name: Self.removalScenario, initialState: Self.deactivatedState)]
        )
        .openTangemPay()
        .verifyAccountClosedBanner()
    }

    private func verifyPayEnabledCalled(requestsBeforeRemoval: Int) {
        XCTContext.runActivity(named: "Verify the account removal request was sent") { _ in
            // The WireMock request journal outlives a single test, so only the increase is meaningful.
            XCTAssertGreaterThan(
                payEnabledRequestCount(),
                requestsBeforeRemoval,
                "Account removal should call \(Self.payEnabledEndpoint)"
            )
        }
    }

    private func payEnabledRequestCount() -> Int {
        wireMockClient.requestCountSync(method: "PATCH", urlPathPattern: Self.payEnabledEndpoint)
    }
}
