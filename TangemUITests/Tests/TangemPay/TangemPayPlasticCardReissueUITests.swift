//
//  TangemPayPlasticCardReissueUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TangemPayPlasticCardReissueUITests: TangemPayPlasticCardUITestCase {
    func testReplacePlasticCardSheet_ShowsReissueOffer() {
        setAllureId(11979)

        let paymentAccount = openPaymentAccount(customer: .plasticActive)
        resetRequestJournal()

        paymentAccount
            .tapCard(cardId: Constants.plasticCardId)
            .tapReplacePlasticCard()
            .verifyContent(country: Constants.country, deliveryFee: Constants.deliveryFee, deliveryTime: Constants.deliveryTime)

        verifyRequestSent(method: "GET", urlPattern: Constants.Endpoint.reissueOffers, named: "plastic reissue offers")
    }

    func testReplacePlasticCard_BalanceBelowDeliveryFee_DisablesReplaceUntilToppedUp() {
        setAllureId(11957)

        let paymentAccount = openPaymentAccount(customer: .plasticActive, isFunded: false)
            .verifyBalanceContains(Constants.emptyBalance)

        paymentAccount
            .tapCard(cardId: Constants.plasticCardId)
            .tapReplacePlasticCard()
            .verifyNotEnoughMoney(deliveryFee: Constants.deliveryFee)
            .tapCancel()
            .tapBack()

        topUpBalance()
        pullToRefresh()

        paymentAccount
            .verifyBalanceContains(Constants.fundedBalance)
            .tapCard(cardId: Constants.plasticCardId)
            .tapReplacePlasticCard()
            .verifyEnoughMoney(deliveryFee: Constants.deliveryFee)
    }

    func testPlasticCardReissue_FromReplaceToActivatedCard() {
        setAllureId(11980)

        let paymentAccount = openPaymentAccount(customer: .plasticActive)

        let cardManagement = paymentAccount
            .tapCard(cardId: Constants.plasticCardId)
            .tapReplacePlasticCard()
            .verifyEnoughMoney(deliveryFee: Constants.deliveryFee)
            .tapReplace()
            .fillDeliveryAddress()
            .tapOrderCard()
            .verifyContent(deliveryDays: Constants.deliveryEtaMaxDays, email: Constants.email)
            .tapShowCard(to: TangemPayCardDetailsScreen.self)

        deliverPlasticOrder(as: .plasticReissueDelivered)

        cardManagement
            .verifyPlasticDeliveryState(email: Constants.email)
            .tapActivatePlasticCard()
            .enterLastFourDigits(Constants.validLastDigits)
            .tapContinue()
            .waitForScreenClosed()
            .verifyPlasticActivating()

        completePlasticActivation(as: .plasticReissueActive)

        cardManagement.waitForPlasticCardActivated()
    }
}

private extension TangemPayPlasticCardReissueUITests {
    enum Constants {
        static let country = "United States"
        static let email = "plastic.user@tangem.com"
        static let deliveryFee = "$4.99"
        static let deliveryTime = Localization.tangempayOrderTypeDeliveryEta(4)
        static let deliveryEtaMaxDays = 4
        static let emptyBalance = "$0.00"
        static let fundedBalance = "$10.00"
        static let plasticCardId = "mock-card-id-plastic"
        static let validLastDigits = "4545"

        enum Endpoint {
            static let reissueOffers = "/bff-v2/v1/product-instances/mock-product-id-plastic/offers"
        }
    }
}
