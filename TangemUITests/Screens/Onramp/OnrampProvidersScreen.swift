//
//  OnrampProvidersScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class OnrampProvidersScreen: ScreenBase<OnrampProvidersScreenElement> {
    private lazy var screenTitle = staticText(.screenTitle)
    private lazy var closeButton = button(.closeButton)

    @discardableResult
    func waitForProviders() -> Self {
        XCTContext.runActivity(named: "Validate OnRamp providers screen elements") { _ in
            waitAndAssertTrue(screenTitle, "Providers screen title should exist")
            waitAndAssertTrue(closeButton, "Close button should exist")

            let amountsQuery = app.staticTexts.matching(NSPredicate(format: "identifier BEGINSWITH 'onrampProviderAmount_'"))
            let firstAmount = amountsQuery.firstMatch
            waitAndAssertTrue(firstAmount, "At least one offer amount should exist")

            let buyButton = app.buttons.matching(NSPredicate(format: "label == 'Buy'"))
                .firstMatch
            waitAndAssertTrue(buyButton, "At least one Buy button should exist")
        }
        return self
    }

    @discardableResult
    func waitForProviderIconsAndNames() -> Self {
        XCTContext.runActivity(named: "Validate offers (amount labels) exist and non-empty") { _ in
            let amountsQuery = app.staticTexts.matching(NSPredicate(format: "identifier BEGINSWITH 'onrampProviderAmount_'"))
            let firstAmount = amountsQuery.firstMatch
            XCTAssertTrue(firstAmount.waitForExistence(timeout: .robustUIUpdate), "At least one offer amount should exist")

            let amounts = amountsQuery.allElementsBoundByIndex
            XCTAssertGreaterThan(amounts.count, 0, "At least one offer should exist")

            for amount in amounts {
                waitAndAssertTrue(amount, "Offer amount should exist")
                let notEmpty = XCTWaiter.wait(
                    for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "label.length > 0"), object: amount)],
                    timeout: .robustUIUpdate
                )
                XCTAssertEqual(notEmpty, .completed, "Offer amount should not be empty: \(amount.identifier)")
            }
        }
        return self
    }

    @discardableResult
    func waitForProviderCard() -> Self {
        XCTContext.runActivity(named: "Validate any available provider offer") { _ in
            let amountsQuery = app.staticTexts.matching(NSPredicate(format: "identifier BEGINSWITH 'onrampProviderAmount_'"))
            let first = amountsQuery.firstMatch
            waitAndAssertTrue(first, "At least one offer amount should exist")

            let amountId = first.identifier
            // Extract provider key from id suffix if present
            if let key = amountId.components(separatedBy: "onrampProviderAmount_").last, !key.isEmpty {
                validateProviderCard(providerName: key)
            }
        }
        return self
    }

    @discardableResult
    func waitForBuyButtons() -> Self {
        XCTContext.runActivity(named: "Validate each provider has a tappable Buy button") { _ in
            let amountsQuery = app.staticTexts.matching(NSPredicate(format: "identifier BEGINSWITH 'onrampProviderAmount_'"))
            let buyButtons = app.buttons.matching(NSPredicate(format: "label == 'Buy'"))

            // Ensure at least one provider exists
            let firstAmount = amountsQuery.firstMatch
            waitAndAssertTrue(firstAmount, "At least one provider offer should exist")

            let amountElements = amountsQuery.allElementsBoundByIndex
            let buyButtonElements = buyButtons.allElementsBoundByIndex

            XCTAssertGreaterThan(amountElements.count, 0, "At least one provider offer should exist")
            XCTAssertGreaterThan(buyButtonElements.count, 0, "At least one Buy button should exist")

            // There should be at least as many Buy buttons as offers
            XCTAssertGreaterThanOrEqual(
                buyButtonElements.count,
                amountElements.count,
                "There should be a Buy button for each provider offer (offers: \(amountElements.count), buys: \(buyButtonElements.count))"
            )
        }
        return self
    }

    @discardableResult
    func tapAnyBuyButtonAndValidateWebView() -> Self {
        XCTContext.runActivity(named: "Tap Buy on any offer and validate webview opens") { _ in
            let buyButton = app.buttons.matching(NSPredicate(format: "label == 'Buy'"))
                .firstMatch
            waitAndAssertTrue(buyButton, "Buy button should exist before tapping")
            XCTAssertTrue(buyButton.isHittable, "Buy button should be hittable before tapping")
            buyButton.tap()

            // Validate that a web view (SFSafariViewController or WKWebView) appears
            let webView = app.webViews.firstMatch
            waitAndAssertTrue(webView, "WebView should appear after tapping Buy")

            app.otherElements["TopBrowserBar"].buttons["Close"].waitAndTap()
        }
        return self
    }

    @discardableResult
    func tapCloseButton() -> OnrampScreen {
        XCTContext.runActivity(named: "Tap Close button") { _ in
            closeButton.waitAndTap()
            return OnrampScreen(app)
        }
    }

    @discardableResult
    func verifyProviderAmount(_ provider: String, contains expectedAmount: String) -> Self {
        XCTContext.runActivity(named: "Validate \(provider) offer amount contains '\(expectedAmount)'") { _ in
            let amount = providerAmount(provider)
            waitAndAssertTrue(amount, "Offer amount of \(provider) should exist")
            XCTAssertTrue(
                amount.label.contains(expectedAmount),
                "Offer amount of \(provider) should contain '\(expectedAmount)' but was '\(amount.label)'"
            )
        }
        return self
    }

    @discardableResult
    func verifyProvider(_ upper: String, isAbove lower: String) -> Self {
        XCTContext.runActivity(named: "Validate \(upper) offer is displayed above \(lower) offer") { _ in
            let upperAmount = providerAmount(upper)
            let lowerAmount = providerAmount(lower)
            waitAndAssertTrue(upperAmount, "Offer amount of \(upper) should exist")
            waitAndAssertTrue(lowerAmount, "Offer amount of \(lower) should exist")
            XCTAssertLessThan(
                upperAmount.frame.minY,
                lowerAmount.frame.minY,
                "\(upper) offer should be above \(lower) offer"
            )
        }
        return self
    }

    @discardableResult
    func verifyProviderUnavailable(_ provider: String) -> Self {
        XCTContext.runActivity(named: "Validate \(provider) offer is marked as not available and Buy is disabled") { _ in
            let badge = providerAmountBadge(provider)
            waitAndAssertTrue(badge, "Badge of \(provider) offer should exist")
            XCTAssertEqual(badge.label, Localization.commonNotAvailable, "Badge of \(provider) offer should be 'Not available'")

            let buyButton = providerBuyButton(provider)
            waitAndAssertTrue(buyButton, "Buy button of \(provider) offer should exist")
            XCTAssertFalse(buyButton.isEnabled, "Buy button of \(provider) offer should be disabled")
        }
        return self
    }

    @discardableResult
    func verifyProviderAvailable(_ provider: String) -> Self {
        XCTContext.runActivity(named: "Validate \(provider) offer has no restriction badge and Buy is enabled") { _ in
            let buyButton = providerBuyButton(provider)
            waitAndAssertTrue(buyButton, "Buy button of \(provider) offer should exist")
            XCTAssertTrue(buyButton.isEnabled, "Buy button of \(provider) offer should be enabled")

            let notAvailableBadge = app.staticTexts
                .matching(identifier: OnrampAccessibilityIdentifiers.providerAmountBadge(name: provider))
                .matching(NSPredicate(format: "label == %@", Localization.commonNotAvailable))
                .firstMatch
            XCTAssertFalse(notAvailableBadge.exists, "\(provider) offer should not be marked as not available")
        }
        return self
    }

    @discardableResult
    func verifyRegionRestrictionNotificationDisplayed() -> Self {
        XCTContext.runActivity(named: "Validate regional restrictions notification is displayed") { _ in
            let title = app.staticTexts
                .matching(identifier: CommonUIAccessibilityIdentifiers.notificationTitle)
                .matching(NSPredicate(format: "label == %@", Localization.expressOnrampRestrictionsTitle))
                .firstMatch
            waitAndAssertTrue(title, "Regional restrictions notification should be displayed")
        }
        return self
    }

    private func providerAmount(_ provider: String) -> XCUIElement {
        let query = app.staticTexts.matching(identifier: OnrampAccessibilityIdentifiers.providerAmount(name: provider))
        return query.firstHittableElement() ?? query.firstMatch
    }

    private func providerAmountBadge(_ provider: String) -> XCUIElement {
        app.staticTexts[OnrampAccessibilityIdentifiers.providerAmountBadge(name: provider)].firstMatch
    }

    private func providerBuyButton(_ provider: String) -> XCUIElement {
        app.buttons[OnrampAccessibilityIdentifiers.providerBuyButton(name: provider)].firstMatch
    }

    private func validateProviderCard(providerName: String) {
        XCTContext.runActivity(named: "Validate provider offer with name: \(providerName)") { _ in
            let amountId = OnrampAccessibilityIdentifiers.providerAmount(name: providerName)
            let amountQuery = app.staticTexts.matching(identifier: amountId)
            let amount = amountQuery.firstMatch
            waitAndAssertTrue(amount, "Provider amount should exist")
            XCTAssertFalse(amount.label.isEmpty, "Provider amount should not be empty")
        }
    }
}

enum OnrampProvidersScreenElement: String, UIElement {
    case screenTitle
    case closeButton

    var accessibilityIdentifier: String {
        switch self {
        case .screenTitle:
            return OnrampAccessibilityIdentifiers.providersScreenTitle
        case .closeButton:
            return CommonUIAccessibilityIdentifiers.closeButton
        }
    }
}
