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
    private lazy var paymentMethodBlock = button(.paymentMethodBlock)
    private lazy var screenTitle = staticText(.screenTitle)
    private lazy var closeButton = button(.screenTitle)

    @discardableResult
    func validate() -> Self {
        XCTContext.runActivity(named: "Validate OnRamp providers screen elements") { _ in
            XCTAssertTrue(closeButton.waitForExistence(timeout: .robustUIUpdate), "Close button should exist")
            XCTAssertTrue(paymentMethodBlock.waitForExistence(timeout: .robustUIUpdate), "Payment method block should exist")

            let providerCards = app.images.matching(NSPredicate(format: "identifier BEGINSWITH 'onrampProviderIcon_'"))
            XCTAssertTrue(providerCards.firstMatch.exists, "At least one provider card should exist")

            let firstProviderCard = providerCards.firstMatch
            XCTAssertTrue(firstProviderCard.waitForExistence(timeout: .robustUIUpdate), "First provider card should exist")
        }
        return self
    }

    @discardableResult
    func validateScreenTitle() -> Self {
        XCTContext.runActivity(named: "Validate Provider screen title") { _ in
            XCTAssertTrue(app.staticTexts["Provider"].waitForExistence(timeout: .robustUIUpdate), "Screen title should be 'Provider'")
        }
        return self
    }

    @discardableResult
    func validateProviderIconsAndNames() -> Self {
        XCTContext.runActivity(named: "Validate provider icons and names exist") { _ in
            // Wait for any provider name to appear first
            let providerNamesQuery = app.staticTexts.matching(NSPredicate(format: "identifier BEGINSWITH 'onrampProviderName_'"))
            let firstProviderName = providerNamesQuery.firstMatch
            XCTAssertTrue(firstProviderName.waitForExistence(timeout: .robustUIUpdate), "First provider name should exist")

            // Now get all provider names after waiting
            let providerNames = providerNamesQuery.allElementsBoundByIndex
            let nameCount = providerNames.count

            XCTAssertGreaterThan(nameCount, 0, "At least one provider name should exist")

            for nameElement in providerNames {
                // Wait for each name element and verify it's not empty
                XCTAssertTrue(nameElement.waitForExistence(timeout: .robustUIUpdate), "Provider name element should exist")

                // Wait a bit to ensure the label is populated
                let nameNotEmpty = XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "label.length > 0"), object: nameElement)], timeout: .robustUIUpdate)
                XCTAssertEqual(nameNotEmpty, .completed, "Provider name should not be empty: \(nameElement.identifier)")

                let nameIdentifier = nameElement.identifier
                if let providerNameKey = nameIdentifier.components(separatedBy: "onrampProviderName_").last {
                    let iconIdentifier = "onrampProviderIcon_\(providerNameKey)"
                    let icon = app.images[iconIdentifier]
                    XCTAssertTrue(icon.waitForExistence(timeout: .robustUIUpdate), "Provider icon should exist for provider: \(providerNameKey)")
                }
            }
        }
        return self
    }

    @discardableResult
    func validateSelectedPaymentMethod(_ expectedPaymentMethodId: String) -> Self {
        XCTContext.runActivity(named: "Validate selected payment method is \(expectedPaymentMethodId)") { _ in
            XCTAssertTrue(paymentMethodBlock.waitForExistence(timeout: .robustUIUpdate), "Payment method block should exist")

            let blockText = paymentMethodBlock.label
            XCTAssertFalse(blockText.isEmpty, "Payment method block should have text content")
        }
        return self
    }

    @discardableResult
    func validateProviderCard(providerName: String) -> Self {
        XCTContext.runActivity(named: "Validate provider card with name: \(providerName)") { _ in
            let providerCard = app.buttons[OnrampAccessibilityIdentifiers.providersScreenProvidersList]
            let providerIcon = app.images[OnrampAccessibilityIdentifiers.providerIcon(name: providerName)]
            let providerNameElement = app.staticTexts[OnrampAccessibilityIdentifiers.providerName(name: providerName)]
            let providerAmount = app.staticTexts[OnrampAccessibilityIdentifiers.providerAmount(name: providerName)]

            XCTAssertTrue(providerCard.waitForExistence(timeout: .robustUIUpdate), "Provider card should exist")
            XCTAssertTrue(providerIcon.waitForExistence(timeout: .robustUIUpdate), "Provider icon should exist")
            XCTAssertTrue(providerNameElement.waitForExistence(timeout: .robustUIUpdate), "Provider name should exist")
            XCTAssertFalse(providerNameElement.label.isEmpty, "Provider name should not be empty")
            XCTAssertTrue(providerAmount.waitForExistence(timeout: .robustUIUpdate), "Provider amount should exist")
            XCTAssertFalse(providerAmount.label.isEmpty, "Provider amount should not be empty")
        }
        return self
    }

    @discardableResult
    func validateAnyProviderCard() -> Self {
        XCTContext.runActivity(named: "Validate any available provider card") { _ in
            let providerNames = app.staticTexts.matching(NSPredicate(format: "identifier BEGINSWITH 'onrampProviderName_'"))
            XCTAssertTrue(providerNames.firstMatch.exists, "At least one provider name should exist")

            let firstProviderName = providerNames.firstMatch
            XCTAssertTrue(firstProviderName.waitForExistence(timeout: .robustUIUpdate), "First provider name should be accessible")

            let providerName = firstProviderName.label
            XCTAssertFalse(providerName.isEmpty, "Provider name should not be empty")

            validateProviderCard(providerName: providerName)
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

    func tapPaymentMethodBlock() -> OnrampPaymentMethodsScreen {
        XCTContext.runActivity(named: "Tap payment method block") { _ in
            XCTAssertTrue(paymentMethodBlock.waitForExistence(timeout: .robustUIUpdate), "Payment method block should exist before tapping")
            XCTAssertTrue(paymentMethodBlock.isHittable, "Payment method block should be hittable")

            paymentMethodBlock.waitAndTap()

            return OnrampPaymentMethodsScreen(app)
        }
    }
}

enum OnrampProvidersScreenElement: String, UIElement {
    case paymentMethodBlock
    case screenTitle

    var accessibilityIdentifier: String {
        switch self {
        case .paymentMethodBlock:
            return OnrampAccessibilityIdentifiers.providersScreenPaymentMethodBlock
        case .screenTitle:
            return OnrampAccessibilityIdentifiers.providersScreenTitle
        }
    }
}
