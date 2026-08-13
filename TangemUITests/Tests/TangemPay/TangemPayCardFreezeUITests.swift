//
//  TangemPayCardFreezeUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TangemPayCardFreezeUITests: BaseTestCase {
    func testFreezeCard_ShowsErrorToast_ThenRetrySucceeds() {
        setAllureId(9555)

        let mainScreen = launchAndImportHotWallet(
            scenarios: [ScenarioConfig(name: "tangem_pay_card_freeze", initialState: "FreezeError")]
        )

        mainScreen
            .openTangemPay()
            .waitForScreen()
            .tapCard()
            .waitForScreen()
            .verifyCardActive()
            .tapFreezeCard()
            .waitForScreen()
            .confirmFreeze()
            .verifyFreezeErrorToast()
            .verifyCardActive()
            .tapFreezeCard()
            .waitForScreen()
            .confirmFreeze()
            .verifyCardFrozen()
    }

    func testUnfreezeCard_ShowsErrorToast_ThenRetrySucceeds() {
        setAllureId(9556)

        let mainScreen = launchAndImportHotWallet(
            scenarios: [ScenarioConfig(name: "tangem_pay_card_freeze", initialState: "UnfreezeError")]
        )

        mainScreen
            .openTangemPay()
            .waitForScreen()
            .tapCard()
            .waitForScreen()
            .verifyCardFrozen()
            .tapUnfreezeCard()
            .waitForScreen()
            .confirmUnfreeze()
            .verifyUnfreezeErrorToast()
            .verifyCardFrozen()
            .tapUnfreezeCard()
            .waitForScreen()
            .confirmUnfreeze()
            .verifyCardActive()
    }

    func testWithdrawAndAddFundsDisabled_WhenCardIsFrozen() {
        setAllureId(9608)

        let mainScreen = launchAndImportHotWallet(
            scenarios: [ScenarioConfig(name: "tangem_pay_card_freeze", initialState: "Frozen")]
        )

        mainScreen
            .openTangemPay()
            .waitForScreen()
            .waitForBalanceLoaded()
            .verifyWithdrawDisabled()
            .verifyAddFundsDisabled()
    }
}
