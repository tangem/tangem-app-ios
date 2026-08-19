//
//  TangemPayCardDetailsUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TangemPayCardDetailsUITests: BaseTestCase {
    func testCardRequisites_DisplayedInCardDetailsAndApplePayGuide() {
        setAllureId(9595)

        let mainScreen = launchAndImportHotWallet(scenarios: [
            ScenarioConfig(name: "tangem_pay_balance_update", initialState: "InitialBalance"),
        ])

        let cardDetails = mainScreen
            .openTangemPay()
            .waitForScreen()
            .tapCard()
            .waitForScreen()

        cardDetails
            .tapShowDetails()
            .waitForRevealedDetails()
            .verifyRequisites()

        cardDetails
            .tapApplePayGuideBanner()
            .waitForScreen()
            .tapShowDetails()
            .waitForRevealedDetails()
            .verifyRequisites()
    }

    func testApplePayGuideRequisites_HiddenIndependentlyFromCardDetails() {
        setAllureId(9593)

        let mainScreen = launchAndImportHotWallet(scenarios: [
            ScenarioConfig(name: "tangem_pay_balance_update", initialState: "InitialBalance"),
        ])

        let cardDetails = mainScreen
            .openTangemPay()
            .waitForScreen()
            .tapCard()
            .waitForScreen()

        cardDetails
            .tapShowDetails()
            .waitForRevealedDetails()

        cardDetails
            .tapApplePayGuideBanner()
            .waitForScreen()
            .verifyRequisitesHidden()
            .tapShowDetails()
            .waitForRevealedDetails()
            .close()
            .waitForRequisitesHiddenOnCard()
    }

    func testCardDetails_ShowsErrorToast_WhenRevealFails() {
        setAllureId(9560)

        let mainScreen = launchAndImportHotWallet(
            scenarios: [
                ScenarioConfig(name: "tangem_pay_balance_update", initialState: "InitialBalance"),
            ],
            extraLaunchEnvironment: ["UITEST_TANGEMPAY_CARD_DETAILS_ERROR": "1"]
        )

        mainScreen
            .openTangemPay()
            .waitForScreen()
            .tapCard()
            .waitForScreen()
            .tapShowDetails()
            .verifyCardDetailsErrorToast()
    }
}
