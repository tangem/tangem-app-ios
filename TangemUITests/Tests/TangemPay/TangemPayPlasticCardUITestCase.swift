//
//  TangemPayPlasticCardUITestCase.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

class TangemPayPlasticCardUITestCase: BaseTestCase {
    enum CustomerState: String {
        case noPlastic = "NoPlastic"
        case plasticDelivered = "PlasticDelivered"
        case plasticDeliveredBasic = "PlasticDeliveredBasic"
        case plasticActive = "PlasticActive"
        case plasticReissueDelivered = "PlasticReissueDelivered"
        case plasticReissueActive = "PlasticReissueActive"
    }

    enum OffersState: String {
        case firstDeliveryFree = "FirstDeliveryFree"
        case paidDelivery = "PaidDelivery"
        case virtualOnly = "VirtualOnly"
        case plasticIncomplete = "PlasticIncomplete"
    }

    func openPaymentAccount(
        customer: CustomerState,
        offers: OffersState = .paidDelivery,
        isFunded: Bool = true,
        isOrderFailing: Bool = false
    ) -> TangemPayMainScreen {
        var scenarios = [
            ScenarioConfig(name: Constants.Scenario.customer, initialState: customer.rawValue),
            ScenarioConfig(name: Constants.Scenario.offers, initialState: offers.rawValue),
        ]

        if isFunded {
            scenarios.append(ScenarioConfig(name: Constants.Scenario.balance, initialState: Constants.State.initialBalance))
        }

        if isOrderFailing {
            scenarios.append(ScenarioConfig(name: Constants.Scenario.order, initialState: Constants.State.orderError))
        }

        return launchAndImportHotWallet(scenarios: scenarios)
            .openTangemPay()
            .waitForScreen()
    }

    func openPlasticOffer(from paymentAccount: TangemPayMainScreen) -> TangemPayOrderCardTypeScreen {
        paymentAccount
            .tapAddCard()
            .waitForScreen()
            .selectPlasticTab()
    }

    func openDeliveryAddressForm(from paymentAccount: TangemPayMainScreen) -> TangemPayOrderCardDataScreen {
        openPlasticOffer(from: paymentAccount)
            .verifySelectEnabled()
            .tapSelectPlastic()
    }

    func orderPlasticCard(from paymentAccount: TangemPayMainScreen) -> TangemPayOrderCardSuccessScreen {
        openDeliveryAddressForm(from: paymentAccount)
            .fillDeliveryAddress()
            .tapOrderCard()
    }

    func refresh(_ paymentAccount: TangemPayMainScreen, untilCardDisplayed cardId: String) {
        pullToRefresh()
        paymentAccount.verifyCardDisplayed(cardId: cardId)
    }

    func switchCustomer(to state: CustomerState) {
        XCTContext.runActivity(named: "Switch the customer to \(state.rawValue)") { _ in
            wireMockClient.setScenarioStateSync(Constants.Scenario.customer, state: state.rawValue)
        }
    }

    func switchOffers(to state: OffersState) {
        XCTContext.runActivity(named: "Switch the offers to \(state.rawValue)") { _ in
            wireMockClient.setScenarioStateSync(Constants.Scenario.offers, state: state.rawValue)
        }
    }

    func topUpBalance() {
        XCTContext.runActivity(named: "Top up the payment account above the delivery fee") { _ in
            wireMockClient.setScenarioStateSync(Constants.Scenario.balance, state: Constants.State.initialBalance)
        }
    }

    func deliverPlasticOrder(as deliveredCustomer: CustomerState) {
        XCTContext.runActivity(named: "Complete the plastic order as \(deliveredCustomer.rawValue)") { _ in
            wireMockClient.setScenarioStateSync(Constants.Scenario.customer, state: deliveredCustomer.rawValue)
            wireMockClient.setScenarioStateSync(Constants.Scenario.order, state: Constants.State.completed)
        }
    }

    func completePlasticActivation(as activatedCustomer: CustomerState = .plasticActive) {
        XCTContext.runActivity(named: "Complete the plastic card activation as \(activatedCustomer.rawValue)") { _ in
            wireMockClient.setScenarioStateSync(Constants.Scenario.customer, state: activatedCustomer.rawValue)
            wireMockClient.setScenarioStateSync(Constants.Scenario.activation, state: Constants.State.completed)
        }
    }

    func resetRequestJournal() {
        wireMockClient.resetRequestJournalSync()
    }

    func verifyRequestSent(method: String, urlPattern: String, named name: String) {
        XCTContext.runActivity(named: "Verify the \(name) request was sent") { _ in
            let predicate = NSPredicate { [wireMockClient] _, _ in
                wireMockClient.requestCountSync(method: method, urlPattern: urlPattern) > 0
            }
            let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
            XCTAssertEqual(
                XCTWaiter().wait(for: [expectation], timeout: .networkRequest),
                .completed,
                "The \(name) request should be sent"
            )
        }
    }
}

private extension TangemPayPlasticCardUITestCase {
    enum Constants {
        enum Scenario {
            static let customer = "tangem_pay_plastic_customer"
            static let offers = "tangem_pay_plastic_offers"
            static let order = "tangem_pay_plastic_order"
            static let activation = "tangem_pay_plastic_activation"
            static let balance = "tangem_pay_balance_update"
        }

        enum State {
            static let initialBalance = "InitialBalance"
            static let orderError = "OrderError"
            static let completed = "Completed"
        }
    }
}
