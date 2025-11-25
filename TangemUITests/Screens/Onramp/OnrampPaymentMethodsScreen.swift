//
//  OnrampPaymentMethodsScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class OnrampPaymentMethodsScreen: ScreenBase<OnrampPaymentMethodsScreenElement> {
    @discardableResult
    func waitForPaymentMethodIconsAndNames() -> Self {
        XCTContext.runActivity(named: "Validate payment method icons and names exist") { _ in
            let paymentMethodCards = app.buttons.matching(identifier: OnrampAccessibilityIdentifiers.paymentMethodCard)

            XCTAssertTrue(paymentMethodCards.firstMatch.waitForExistence(timeout: .robustUIUpdate), "At least one payment method card should exist")

            let cardCount = paymentMethodCards.count
            XCTAssertGreaterThan(cardCount, 0, "At least one payment method should exist")

            for index in 0 ..< cardCount {
                let card = paymentMethodCards.element(boundBy: index)
                XCTAssertTrue(card.exists, "Payment method card at index \(index) should exist")

                let knownPaymentMethods = ["apple-pay", "card", "invoice-revolut-pay"]

                for paymentMethodId in knownPaymentMethods {
                    let iconId = OnrampAccessibilityIdentifiers.paymentMethodIcon(id: paymentMethodId)
                    let nameId = OnrampAccessibilityIdentifiers.paymentMethodName(id: paymentMethodId)

                    let iconExists = app.images[iconId].exists
                    let nameExists = app.staticTexts[nameId].exists

                    if iconExists, nameExists {
                        XCTAssertTrue(iconExists, "Payment method icon should exist for ID: \(paymentMethodId)")
                        XCTAssertTrue(nameExists, "Payment method name should exist for ID: \(paymentMethodId)")

                        let name = app.staticTexts[nameId]
                        XCTAssertFalse(name.label.isEmpty, "Payment method name should not be empty for ID: \(paymentMethodId)")
                    }
                }
            }
        }
        return self
    }

    func selectPaymentMethod(at index: Int = 0) -> OnrampProvidersScreen {
        XCTContext.runActivity(named: "Select payment method at index \(index)") { _ in
            let paymentMethodCards = app.buttons.matching(identifier: OnrampAccessibilityIdentifiers.paymentMethodCard)

            XCTAssertGreaterThan(paymentMethodCards.count, 0, "At least one payment method should exist")
            XCTAssertLessThan(index, paymentMethodCards.count, "Index \(index) should be less than available payment methods count: \(paymentMethodCards.count)")

            let selectedCard = paymentMethodCards.element(boundBy: index)
            waitAndAssertTrue(selectedCard, "Payment method card at index \(index) should exist")
            selectedCard.waitAndTap()
            return OnrampProvidersScreen(app)
        }
    }
}

enum OnrampPaymentMethodsScreenElement: String, UIElement {
    case paymentMethodCard

    var accessibilityIdentifier: String {
        switch self {
        case .paymentMethodCard:
            return OnrampAccessibilityIdentifiers.paymentMethodCard
        }
    }
}
