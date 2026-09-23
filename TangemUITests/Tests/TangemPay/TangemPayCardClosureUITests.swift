//
//  TangemPayCardClosureUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TangemPayCardClosureUITests: BaseTestCase {
    func testCloseCard_IsDisabled_WhenAccountHasSingleCard() {
        setAllureId(10104)

        launchAndImportHotWallet()
            .openTangemPay()
            .waitForScreen()
            .tapCard()
            .waitForScreen()
            .verifyCloseCardDisabled()
    }

    func testCloseCardSheet_ShowsWarningContent() {
        setAllureId(10106)

        launchAndImportHotWallet(scenarios: [
            ScenarioConfig(name: Constants.Scenario.cardIssue, initialState: Constants.State.twoCards),
        ])
        .openTangemPay()
        .waitForScreen()
        .tapCard(cardId: Constants.Card.secondId)
        .waitForScreen()
        .tapCloseCard()
        .waitForScreen()
        .verifySheetContent()
    }

    func testCloseActiveCard_ReturnsToRemainingCardAndRemovesClosedOne() {
        setAllureId(10102)

        closeSecondCard(initialCustomerState: Constants.State.twoCards)
    }

    func testCloseFrozenCard_ReturnsToRemainingCardAndRemovesClosedOne() {
        setAllureId(10103)

        closeSecondCard(initialCustomerState: Constants.State.secondCardFrozen, isFrozen: true)
    }

    private func closeSecondCard(initialCustomerState: String, isFrozen: Bool = false) {
        let cardDetails = launchAndImportHotWallet(scenarios: [
            ScenarioConfig(name: Constants.Scenario.cardClose, initialState: initialCustomerState),
            ScenarioConfig(name: Constants.Scenario.closeOrder, initialState: "Started"),
        ])
        .openTangemPay()
        .waitForScreen()
        .tapCard(cardId: Constants.Card.secondId)
        .waitForScreen()

        if isFrozen {
            cardDetails.verifyCardFrozen()
        }

        let closeRequestsBefore = closeRequestCount()
        let orderRequestsBefore = closeOrderRequestCount()

        cardDetails
            .tapCloseCard()
            .waitForScreen()
            .confirmClose()
            .verifyCardClosingInProgress()

        XCTContext.runActivity(named: "Verify the card close was requested") { _ in
            XCTAssertGreaterThan(
                closeRequestCount(),
                closeRequestsBefore,
                "Confirming the sheet should request \(Constants.Endpoint.close)"
            )
        }

        // The customer state goes first: the poller reloads customer info as soon as it sees COMPLETED.
        wireMockClient.setScenarioStateSync(Constants.Scenario.cardClose, state: Constants.State.afterCardClose)
        wireMockClient.setScenarioStateSync(Constants.Scenario.closeOrder, state: "Completed")

        cardDetails.waitForCardClosingCompleted()

        XCTContext.runActivity(named: "Verify the close order was polled") { _ in
            XCTAssertGreaterThan(
                closeOrderRequestCount(),
                orderRequestsBefore,
                "Closing the card should poll \(Constants.Endpoint.closeOrder)"
            )
        }

        cardDetails
            .verifyCardNameNotDisplayed(Constants.Card.secondName)
            .tapBack()
            .waitForScreen()
            .verifyCardNotDisplayed(cardId: Constants.Card.secondId)
            .verifyCardDisplayed(cardId: Constants.Card.firstId)
    }

    private func closeRequestCount() -> Int {
        wireMockClient.requestCountSync(method: "POST", urlPathPattern: Constants.Endpoint.close)
    }

    private func closeOrderRequestCount() -> Int {
        wireMockClient.requestCountSync(method: "GET", urlPathPattern: Constants.Endpoint.closeOrder)
    }
}

private extension TangemPayCardClosureUITests {
    enum Constants {
        enum Scenario {
            static let cardIssue = "tangem_pay_card_issue"
            static let cardClose = "tangem_pay_card_close"
            static let closeOrder = "tangem_pay_close_card_order"
        }

        enum State {
            static let twoCards = "TwoCards"
            static let secondCardFrozen = "SecondCardFrozen"
            static let afterCardClose = "AfterCardClose"
        }

        enum Card {
            static let firstId = "mock-card-id"
            static let secondId = "mock-card-id-2"
            static let secondName = "My Card 2"
        }

        enum Endpoint {
            static let close = "/bff-v2/v1/customer/card/close"
            static let closeOrder = "/bff-v2/v1/order/mock-close-order-001"
        }
    }
}
