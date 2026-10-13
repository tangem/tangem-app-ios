//
//  TangemPayPlasticCardOrderUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TangemPayPlasticCardOrderUITests: TangemPayPlasticCardUITestCase {
    func testOffersScreen_ShowsVirtualAndPlasticOffers_PerTariff() {
        setAllureId(11978)

        let paymentAccount = openPaymentAccount(customer: .plasticDelivered)

        paymentAccount
            .tapAddCard()
            .waitForScreen()
            .verifyHeader()
            .verifyPlusBackground()
            .verifyVirtualTabSelected()
            .verifyVirtualOffer(issueFee: Constants.virtualIssueFee)
            .verifySelectEnabled()
            .verifyPlasticTabLabel()
            .selectPlasticTab()
            .verifyHeader()
            .verifyPlusBackground()
            .verifyPlasticOffer(country: Constants.country, deliveryFee: Constants.deliveryFee, deliveryTime: Constants.deliveryTime)
            .verifySelectEnabled()
            .close()

        switchCustomer(to: .plasticDeliveredBasic)
        refresh(paymentAccount, untilCardDisplayed: Constants.basicVirtualCardId)

        paymentAccount
            .tapAddCard()
            .waitForScreen()
            .verifyHeader()
            .verifyBasicBackground()
            .verifyVirtualTabSelected()
            .verifyVirtualOffer(issueFee: Constants.virtualIssueFee)
            .selectPlasticTab()
            .verifyBasicBackground()
            .verifyPlasticOffer(country: Constants.country, deliveryFee: Constants.deliveryFee, deliveryTime: Constants.deliveryTime)
            .verifySelectEnabled()
    }

    func testPlusFirstPlasticDelivery_IsFree_UntilPlasticCardExists() {
        setAllureId(11955)

        let paymentAccount = openPaymentAccount(customer: .noPlastic, offers: .firstDeliveryFree)

        openPlasticOffer(from: paymentAccount)
            .verifyFirstDeliveryFree()
            .verifySelectEnabled()
            .close()

        switchCustomer(to: .plasticActive)
        switchOffers(to: .paidDelivery)
        refresh(paymentAccount, untilCardDisplayed: Constants.plasticCardId)

        openPlasticOffer(from: paymentAccount)
            .verifyNoFirstDeliveryFree()
            .verifyEnoughMoney(deliveryFee: Constants.deliveryFee)
            .verifySelectEnabled()
    }

    func testPlasticOffer_BalanceBelowDeliveryFee_DisablesSelectUntilToppedUp() {
        setAllureId(11956)

        let paymentAccount = openPaymentAccount(customer: .noPlastic, isFunded: false)
            .verifyBalanceContains(Constants.emptyBalance)

        openPlasticOffer(from: paymentAccount)
            .verifyNotEnoughMoney(deliveryFee: Constants.deliveryFee)
            .verifySelectDisabled()
            .close()

        topUpBalance()
        pullToRefresh()

        paymentAccount.verifyBalanceContains(Constants.fundedBalance)

        openPlasticOffer(from: paymentAccount)
            .verifyEnoughMoney(deliveryFee: Constants.deliveryFee)
            .verifySelectEnabled()
    }

    func testPlasticOffer_IsUnavailable_WithoutCompletePlasticOffer() {
        setAllureId(11959)

        let paymentAccount = openPaymentAccount(customer: .noPlastic, offers: .virtualOnly)

        openPlasticOffer(from: paymentAccount)
            .verifyPlasticUnavailable(country: Constants.country)
            .verifySelectDisabled()
            .close()

        switchOffers(to: .plasticIncomplete)
        resetRequestJournal()

        let reopenedPaymentAccount = paymentAccount
            .tapBack()
            .openTangemPay()
            .waitForScreen()

        verifyRequestSent(method: "GET", urlPattern: Constants.Endpoint.offers, named: "customer offers")

        openPlasticOffer(from: reopenedPaymentAccount)
            .verifyPlasticUnavailable(country: Constants.country)
            .verifySelectDisabled()
    }

    func testDeliveryAddressForm_ValidatesRequiredAndLatinOnlyFields() {
        setAllureId(11898)

        let paymentAccount = openPaymentAccount(customer: .noPlastic)

        openDeliveryAddressForm(from: paymentAccount)
            .clearNameOnCard()
            .leaveEditableFieldsEmpty()
            .verifyRequiredErrors()
            .enterText(Constants.nameOnCardWithForbiddenSymbol, into: .nameOnCard)
            .verifyInvalidTextError(on: .nameOnCard)
            .enterText(Constants.nonLatinCity, into: .city)
            .verifyLatinOnlyError(on: .city)
    }

    func testDeliveryAddressForm_IsPrefilledFromProfile() {
        setAllureId(11954)

        let paymentAccount = openPaymentAccount(customer: .noPlastic)

        openDeliveryAddressForm(from: paymentAccount)
            .verifyPrefilledData(nameOnCard: Constants.virtualEmbossName, country: Constants.country, email: Constants.email)
    }

    func testFollowUpPlasticOrder_PrefillsNameOnCardFromPlasticCard() {
        setAllureId(11897)

        let paymentAccount = openPaymentAccount(customer: .plasticActive)

        openDeliveryAddressForm(from: paymentAccount)
            .verifyNameOnCard(Constants.plasticEmbossName)
    }

    func testPlasticOrderFailure_ShowsRetrySheet() {
        setAllureId(11971)

        let paymentAccount = openPaymentAccount(customer: .noPlastic, isOrderFailing: true)

        openDeliveryAddressForm(from: paymentAccount)
            .fillDeliveryAddress()
            .tapOrderCardExpectingError()
            .verifyContent()
    }

    func testPlasticOrderSuccess_ShowsCardOrderedScreenAndStartsPolling() {
        setAllureId(11982)

        let paymentAccount = openPaymentAccount(customer: .noPlastic)
        resetRequestJournal()

        orderPlasticCard(from: paymentAccount)
            .verifyContent(deliveryDays: Constants.deliveryEtaMaxDays, email: Constants.email)

        verifyRequestSent(method: "POST", urlPattern: Constants.Endpoint.placeOrder, named: "place plastic order")
        verifyRequestSent(method: "GET", urlPattern: Constants.Endpoint.plasticOrderStatus, named: "plastic order status")
    }
}

private extension TangemPayPlasticCardOrderUITests {
    enum Constants {
        static let country = "United States"
        static let email = "plastic.user@tangem.com"
        static let virtualIssueFee = "$1.25"
        static let deliveryFee = "$4.99"
        static let deliveryTime = "2–4 business days"
        static let deliveryEtaMaxDays = 4
        static let emptyBalance = "$0.00"
        static let fundedBalance = "$10.00"
        static let virtualEmbossName = "HOT WALLET USER"
        static let plasticEmbossName = "PLASTIC CARD USER"
        static let nameOnCardWithForbiddenSymbol = "John@Doe"
        static let nonLatinCity = "Zürich"
        static let basicVirtualCardId = "mock-card-id-basic"
        static let plasticCardId = "mock-card-id-plastic"

        enum Endpoint {
            static let placeOrder = "/bff-v2/v1/order"
            static let offers = "/bff-v2/v1/customer/offers"
            static let plasticOrderStatus = "/bff-v2/v1/order/mock-plastic-order-001"
        }
    }
}
