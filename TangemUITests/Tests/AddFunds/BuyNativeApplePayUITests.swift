//
//  BuyNativeApplePayUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class BuyNativeApplePayUITests: BaseTestCase {
    func testBuy_NativeApplePayOfferIsDisplayedAndOpensPaymentSheet() {
        setAllureId(11509)

        launchApp(tangemApiType: .mock, expressApiType: .mock, scenarios: Constants.scenarios)

        let applePaySheet = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(Constants.token)
            .tapBuyButton()
            .enterAmount(Constants.amount)
            .waitForProvidersToLoad()
            .verifyNativeApplePayOffer(provider: Constants.provider, cryptoAmount: Constants.cryptoAmount)
            .tapNativeApplePayButton(provider: Constants.provider)
            .waitForSheetDisplayed(cryptoAmount: Constants.cryptoAmount)

        applePaySheet.close()
    }

    func testBuy_NativeApplePayRequestsKYCVerification() {
        setAllureId(11511)

        launchApp(tangemApiType: .mock, expressApiType: .mock, scenarios: Constants.scenarios)

        let applePaySheet = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(Constants.token)
            .tapBuyButton()
            .enterAmount(Constants.amount)
            .waitForProvidersToLoad()
            .tapNativeApplePayButton(provider: Constants.provider)
            .waitForSheetDisplayed(cryptoAmount: Constants.cryptoAmount)

        applePaySheet
            .confirmPayment(email: Constants.email, billing: Constants.billing)
            .waitForSheetDisplayed(provider: Constants.provider)
            .tapVerify()
    }
}

private extension BuyNativeApplePayUITests {
    enum Constants {
        static let token = "Polygon"
        static let amount = "100"
        static let cryptoAmount = "488.24938338"
        static let provider = "Mercuryo"
        static let email = "test@example.com"

        static let billing = ApplePayBillingAddress(
            firstName: "Test",
            lastName: "User",
            street: "1 Main Street",
            city: "Austin",
            state: "TX",
            zip: "73301"
        )

        static let scenarios = [
            ScenarioConfig(name: "onramp_native_apple_pay", initialState: "Enabled"),
        ]
    }
}
