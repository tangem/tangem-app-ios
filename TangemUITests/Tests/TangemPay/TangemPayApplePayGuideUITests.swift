//
//  TangemPayApplePayGuideUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TangemPayApplePayGuideUITests: BaseTestCase {
    func testApplePayGuide_ShowsRequisitesWithCopyControls_FromPaymentAccount() {
        setAllureId(9569)

        let cardDetails = launchAndImportHotWallet()
            .openTangemPay()
            .waitForScreen()
            .tapCard()
            .waitForScreen()
            .verifyApplePayGuideBannerVisible()

        cardDetails
            .tapApplePayGuideBanner()
            .waitForScreen()
            .tapShowDetails()
            .waitForRevealedDetails()
            .verifyRequisites()
            .tapCopyCardNumber()
            .verifyToastVisible(text: "Number copied")
            .tapCopyExpiration()
            .verifyToastVisible(text: "Expiration date copied")
            .tapCopyCvc()
            .verifyToastVisible(text: "CVC copied")
    }

    func testApplePayGuideBanner_StaysDismissed_AfterBackgroundAndRestart() {
        setAllureId(9574)

        let paymentAccount = launchAndImportHotWallet()
            .openTangemPay()
            .waitForScreen()
            .verifyApplePayGuideBannerVisible()
            .closeApplePayGuideBanner()
            .verifyApplePayGuideBannerHidden()

        minimizeApp()
        maximizeApp()

        paymentAccount.verifyApplePayGuideBannerHidden()

        relaunchKeepingState()

        MainScreen(app)
            .openTangemPay()
            .waitForScreen()
            .waitForBalanceLoaded()
            .verifyApplePayGuideBannerHidden()
            .tapCard()
            .waitForScreen()
            .verifyApplePayGuideBannerHidden()
    }

    private func relaunchKeepingState() {
        XCTContext.runActivity(named: "Restart the app keeping wallets and settings") { _ in
            app.terminate()
            launchApp(
                tangemApiType: .mock,
                visaApiType: .mock,
                keepWallets: true,
                scenarios: [ScenarioConfig(name: "tangem_pay_eligibility", initialState: "PaeraCustomer")]
            )
        }
    }
}
