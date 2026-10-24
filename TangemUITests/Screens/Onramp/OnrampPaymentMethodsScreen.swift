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

            let allIconsLoaded = XCTNSPredicateExpectation(
                predicate: NSPredicate { _, _ in iconsQuery.count == namesQuery.count },
                object: nil
            )
            _ = XCTWaiter().wait(for: [allIconsLoaded], timeout: .robustUIUpdate)

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

    @discardableResult
    func waitForScreenTitleDisplayed() -> Self {
        XCTContext.runActivity(named: "Validate payment methods screen title is displayed") { _ in
            let title = app.staticTexts[OnrampAccessibilityIdentifiers.providersScreenTitle].firstMatch
            waitAndAssertTrue(title, "Payment methods screen title should exist")
        }
        return self
    }

    @discardableResult
    func waitForPaymentMethodAmountsDisplayed() -> Self {
        XCTContext.runActivity(named: "Validate each payment method shows an amount") { _ in
            let amountsQuery = app.staticTexts.matching(NSPredicate(format: "identifier BEGINSWITH %@", "onrampProviderAmount_"))
            waitAndAssertTrue(amountsQuery.firstMatch, "At least one payment method amount should exist")

            let amounts = amountsQuery.allElementsBoundByIndex
            for amount in amounts {
                waitAndAssertTrue(amount, "Payment method amount should exist: \(amount.identifier)")
                let notEmpty = XCTWaiter.wait(
                    for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "label.length > 0"), object: amount)],
                    timeout: .robustUIUpdate
                )
                XCTAssertEqual(notEmpty, .completed, "Payment method amount should not be empty: \(amount.identifier)")
            }
        }
        return self
    }

    @discardableResult
    func waitForBestRateBadgeDisplayed() -> Self {
        XCTContext.runActivity(named: "Validate at least one 'Best rate' badge is displayed") { _ in
            // Only the "best" badge case renders an image (a star icon); "loss"/"restricted" render text instead.
            let badgesQuery = app.images.matching(NSPredicate(format: "identifier BEGINSWITH %@", "onrampBestRateBadge_"))
            waitAndAssertTrue(badgesQuery.firstMatch, "At least one 'Best rate' badge should be displayed")
        }
        return self
    }

    @discardableResult
    func waitForProviderCountAndSpeedDisplayed() -> Self {
        XCTContext.runActivity(named: "Validate provider count and speed badges are displayed") { _ in
            let countsQuery = app.staticTexts.matching(NSPredicate(format: "identifier BEGINSWITH %@", "onrampProviderCount_"))
            let timesQuery = app.staticTexts.matching(NSPredicate(format: "identifier BEGINSWITH %@", "onrampProviderTime_"))
            waitAndAssertTrue(countsQuery.firstMatch, "At least one provider count badge should exist")
            waitAndAssertTrue(timesQuery.firstMatch, "At least one provider speed badge should exist")
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

    func selectPaymentMethod(id: String) -> OnrampProvidersScreen {
        XCTContext.runActivity(named: "Select payment method '\(id)'") { _ in
            let selectedCard = app.buttons
                .matching(identifier: OnrampAccessibilityIdentifiers.paymentMethodCard)
                .containing(.staticText, identifier: OnrampAccessibilityIdentifiers.paymentMethodName(id: id))
                .firstMatch
            waitAndAssertTrue(selectedCard, "Payment method card '\(id)' should exist")
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
