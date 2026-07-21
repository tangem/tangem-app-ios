//
//  TangemPayKYCUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TangemPayKYCUITests: BaseTestCase {
    func testKycInProgressSheet_ClosesAndStatusRemainsOnMain() {
        setAllureId(9643)

        launchAndImportHotWallet(
            scenarios: [ScenarioConfig(name: "tangem_pay_kyc_status", initialState: "InProgress")]
        )
        .verifyTangemPayTileShowsKycInProgress()
        .openTangemPayKycStatusSheet()
        .waitForSheet()
        .close()
        .verifyTangemPayTileShowsKycInProgress()
    }

    func testKycRejectedStatus_ShownOnMainAndInSheet() {
        setAllureId(9517)

        launchAndImportHotWallet(
            scenarios: [ScenarioConfig(name: "tangem_pay_kyc_status", initialState: "Declined")]
        )
        .verifyTangemPayTileShowsKycRejected()
        .openTangemPayKycDeclinedSheet()
        .waitForSheet()
    }
}
