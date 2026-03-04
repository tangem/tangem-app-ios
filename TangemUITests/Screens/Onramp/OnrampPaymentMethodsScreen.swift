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
            let iconsQuery = app.images.matching(NSPredicate(format: "identifier BEGINSWITH %@", OnrampAccessibilityIdentifiers.paymentMethodIconPrefix))
            let namesQuery = app.staticTexts.matching(NSPredicate(format: "identifier BEGINSWITH %@", OnrampAccessibilityIdentifiers.paymentMethodNamePrefix))

            let firstIcon = iconsQuery.firstMatch
            XCTAssertTrue(firstIcon.waitForExistence(timeout: .robustUIUpdate), "At least one payment method icon should exist")

            let icons = iconsQuery.allElementsBoundByIndex
            let names = namesQuery.allElementsBoundByIndex

            XCTAssertGreaterThan(icons.count, 0, "At least one payment method icon should exist")
            XCTAssertGreaterThan(names.count, 0, "At least one payment method name should exist")
            XCTAssertEqual(icons.count, names.count, "Each payment method should have both an icon and a name")

            for icon in icons {
                waitAndAssertTrue(icon, "Payment method icon should exist: \(icon.identifier)")
            }

            for name in names {
                waitAndAssertTrue(name, "Payment method name should exist: \(name.identifier)")
                let notEmpty = XCTWaiter.wait(
                    for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "label.length > 0"), object: name)],
                    timeout: .robustUIUpdate
                )
                XCTAssertEqual(notEmpty, .completed, "Payment method name should not be empty: \(name.identifier)")
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
