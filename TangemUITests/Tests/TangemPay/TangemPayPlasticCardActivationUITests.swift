//
//  TangemPayPlasticCardActivationUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TangemPayPlasticCardActivationUITests: TangemPayPlasticCardUITestCase {
    func testCompletedPlasticOrder_ShowsDeliveryStateAndActivationEntries() {
        setAllureId(11972)

        let paymentAccount = openPaymentAccount(customer: .noPlastic)

        orderPlasticCard(from: paymentAccount)
            .tapShowCard(to: TangemPayMainScreen.self)

        deliverPlasticOrder(as: .plasticDelivered)

        paymentAccount
            .verifyPlasticDeliveryBanner()
            .tapActivateCardOnDeliveryBanner()
            .verifyInitialState()
            .close(to: TangemPayCardDetailsScreen.self)
            .verifyPlasticDeliveryState(email: Constants.email)
            .tapBack()
            .tapIssuingCard()
            .verifyPlasticDeliveryState(email: Constants.email)
            .tapActivatePlasticCard()
            .verifyInitialState()
    }

    func testActivation_WithWrongLastDigits_ShowsInvalidDigitsError() {
        setAllureId(11974)

        let paymentAccount = openPaymentAccount(customer: .plasticDelivered)
        resetRequestJournal()

        paymentAccount
            .verifyPlasticDeliveryBanner()
            .tapActivateCardOnDeliveryBanner()
            .verifyInitialState()
            .enterLastFourDigits(Constants.wrongLastDigits)
            .tapContinue()
            .verifyActivatingHint()
            .verifyInvalidDigitsHint()

        verifyRequestSent(method: "POST", urlPattern: Constants.Endpoint.order, named: "plastic activation order")
    }

    func testActivationScreen_IsShownForPlusAndBasicTariffs() {
        setAllureId(11976)

        let paymentAccount = openPaymentAccount(customer: .plasticDelivered)

        paymentAccount
            .verifyPlasticDeliveryBanner()
            .tapActivateCardOnDeliveryBanner()
            .verifyInitialState()
            .close(to: TangemPayCardDetailsScreen.self)
            .tapBack()

        switchCustomer(to: .plasticDeliveredBasic)
        refresh(paymentAccount, untilCardDisplayed: Constants.basicVirtualCardId)

        paymentAccount
            .tapIssuingCard()
            .verifyPlasticDeliveryState(email: Constants.email)
            .tapActivatePlasticCard()
            .verifyInitialState()
    }

    func testPlasticCardOrder_FromOrderToActivatedCard() {
        setAllureId(11894)

        let paymentAccount = openPaymentAccount(customer: .noPlastic)

        orderPlasticCard(from: paymentAccount)
            .verifyContent(deliveryDays: Constants.deliveryEtaMaxDays, email: Constants.email)
            .tapShowCard(to: TangemPayMainScreen.self)

        deliverPlasticOrder(as: .plasticDelivered)

        let cardManagement = paymentAccount
            .verifyPlasticDeliveryBanner()
            .tapActivateCardOnDeliveryBanner()
            .enterLastFourDigits(Constants.validLastDigits)
            .tapContinue()
            .waitForScreenClosed()
            .verifyPlasticActivating()

        completePlasticActivation()

        cardManagement.waitForPlasticCardActivated()
    }
}

private extension TangemPayPlasticCardActivationUITests {
    enum Constants {
        static let email = "plastic.user@tangem.com"
        static let deliveryEtaMaxDays = 4
        static let wrongLastDigits = "1234"
        static let validLastDigits = "4545"
        static let basicVirtualCardId = "mock-card-id-basic"

        enum Endpoint {
            static let order = "/bff-v2/v1/order"
        }
    }
}
