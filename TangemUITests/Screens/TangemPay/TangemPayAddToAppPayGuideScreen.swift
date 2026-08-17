//
//  TangemPayAddToAppPayGuideScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TangemPayAddToAppPayGuideScreen: ScreenBase<TangemPayAddToAppPayGuideScreenElement> {
    private lazy var container = app.descendants(matching: .any)[TangemPayAccessibilityIdentifiers.addToApplePayGuideContainer].firstMatch
    private lazy var showDetailsButton = scopedElement(TangemPayAccessibilityIdentifiers.cardDetailsShowButton)
    private lazy var cardNumberValue = scopedElement(TangemPayAccessibilityIdentifiers.cardDetailsNumberValue)
    private lazy var cardExpirationValue = scopedElement(TangemPayAccessibilityIdentifiers.cardDetailsExpirationValue)
    private lazy var cardCvcValue = scopedElement(TangemPayAccessibilityIdentifiers.cardDetailsCvcValue)
    private lazy var copyNumberButton = scopedElement(TangemPayAccessibilityIdentifiers.cardDetailsCopyNumber)
    private lazy var copyExpirationButton = scopedElement(TangemPayAccessibilityIdentifiers.cardDetailsCopyExpiration)
    private lazy var copyCvcButton = scopedElement(TangemPayAccessibilityIdentifiers.cardDetailsCopyCvc)
    private lazy var closeButton = button(.closeButton)

    @discardableResult
    func waitForScreen() -> Self {
        XCTContext.runActivity(named: "Wait for Apple/Google Pay guide") { _ in
            waitAndAssertTrue(showDetailsButton, "Show details button should be displayed in the Apple/Google Pay guide")
            return self
        }
    }

    @discardableResult
    func tapShowDetails() -> Self {
        XCTContext.runActivity(named: "Tap Show details inside the guide") { _ in
            showDetailsButton.waitAndTap()
            return self
        }
    }

    @discardableResult
    func waitForRevealedDetails() -> Self {
        XCTContext.runActivity(named: "Wait for requisites to be revealed inside the guide") { _ in
            waitAndAssertTrue(cardNumberValue, timeout: .networkRequest, "Card number should be displayed inside the guide")
            waitAndAssertTrue(cardExpirationValue, "Card expiration should be displayed inside the guide")
            waitAndAssertTrue(cardCvcValue, "Card CVC should be displayed inside the guide")
            return self
        }
    }

    @discardableResult
    func verifyRequisites() -> Self {
        XCTContext.runActivity(named: "Verify revealed card requisites inside the guide") { _ in
            waitAndAssertTrue(cardNumberValue, timeout: .networkRequest, "Card number should be displayed inside the guide")
            waitAndAssertTrue(cardExpirationValue, "Card expiration should be displayed inside the guide")
            waitAndAssertTrue(cardCvcValue, "Card CVC should be displayed inside the guide")
            XCTAssertTrue(cardNumberValue.label.contains("4242 4242 4242"), "Card number should contain the mock PAN prefix inside the guide")
            XCTAssertEqual(cardExpirationValue.label, "12/28", "Card expiration should match the mock value inside the guide")
            XCTAssertEqual(cardCvcValue.label, "123", "Card CVC should match the mock value inside the guide")
            return self
        }
    }

    @discardableResult
    func verifyRequisitesHidden() -> Self {
        XCTContext.runActivity(named: "Verify requisites are hidden inside the guide") { _ in
            waitAndAssertTrue(showDetailsButton, "Show details button should be displayed while the guide card is hidden")
            XCTAssertTrue(
                cardNumberValue.waitForNonExistence(timeout: .conditional),
                "Card number should not be revealed inside the guide"
            )
            XCTAssertTrue(
                cardExpirationValue.waitForNonExistence(timeout: .conditional),
                "Card expiration should not be revealed inside the guide"
            )
            XCTAssertTrue(
                cardCvcValue.waitForNonExistence(timeout: .conditional),
                "Card CVC should not be revealed inside the guide"
            )
            return self
        }
    }

    @discardableResult
    func tapCopyCardNumber() -> Self {
        XCTContext.runActivity(named: "Tap copy card number inside the guide") { _ in
            copyNumberButton.waitAndTap()
            return self
        }
    }

    @discardableResult
    func tapCopyExpiration() -> Self {
        XCTContext.runActivity(named: "Tap copy expiration date inside the guide") { _ in
            copyExpirationButton.waitAndTap()
            return self
        }
    }

    @discardableResult
    func tapCopyCvc() -> Self {
        XCTContext.runActivity(named: "Tap copy CVC inside the guide") { _ in
            copyCvcButton.waitAndTap()
            return self
        }
    }

    @discardableResult
    func close() -> TangemPayCardDetailsScreen {
        XCTContext.runActivity(named: "Close the Apple/Google Pay guide") { _ in
            closeButton.waitAndTap()
            return TangemPayCardDetailsScreen(app)
        }
    }

    private func scopedElement(_ identifier: String) -> XCUIElement {
        container.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }
}

enum TangemPayAddToAppPayGuideScreenElement: String, UIElement {
    case closeButton

    var accessibilityIdentifier: String {
        switch self {
        case .closeButton:
            TangemPayAccessibilityIdentifiers.addToApplePayGuideCloseButton
        }
    }
}
