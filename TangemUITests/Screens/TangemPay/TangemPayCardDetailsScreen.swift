//
//  TangemPayCardDetailsScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import UIKit
import TangemAccessibilityIdentifiers

final class TangemPayCardDetailsScreen: ScreenBase<TangemPayCardDetailsScreenElement> {
    private lazy var changePinRow = button(.changePinRow)
    private lazy var freezeRowActive = button(.freezeCardRowStateActive)
    private lazy var freezeRowFrozen = button(.freezeCardRowStateFrozen)
    private lazy var showDetailsButton = button(.cardDetailsShowButton)
    private lazy var hideDetailsButton = button(.cardDetailsHideButton)
    private lazy var cardNumberValue = staticText(.cardDetailsNumberValue)
    private lazy var cardExpirationValue = staticText(.cardDetailsExpirationValue)
    private lazy var cardCvcValue = staticText(.cardDetailsCvcValue)
    private lazy var copyNumberButton = button(.cardDetailsCopyNumber)
    private lazy var copyExpirationButton = button(.cardDetailsCopyExpiration)
    private lazy var copyCvcButton = button(.cardDetailsCopyCvc)

    @discardableResult
    func waitForScreen() -> Self {
        XCTContext.runActivity(named: "Wait for Tangem Pay card details screen") { _ in
            waitAndAssertTrue(changePinRow, "Change PIN row should be displayed on Tangem Pay card details screen")
            return self
        }
    }

    @discardableResult
    func tapChangePin() -> TangemPayPinScreen {
        XCTContext.runActivity(named: "Tap Change PIN row") { _ in
            changePinRow.waitAndTap()
            return TangemPayPinScreen(app)
        }
    }

    @discardableResult
    func tapFreezeCard() -> TangemPayFreezeConfirmationSheet {
        XCTContext.runActivity(named: "Tap Freeze card row") { _ in
            freezeRowActive.waitAndTap()
            return TangemPayFreezeConfirmationSheet(app)
        }
    }

    @discardableResult
    func tapUnfreezeCard() -> TangemPayUnfreezeConfirmationSheet {
        XCTContext.runActivity(named: "Tap Unfreeze card row") { _ in
            freezeRowFrozen.waitAndTap()
            return TangemPayUnfreezeConfirmationSheet(app)
        }
    }

    @discardableResult
    func verifyCardFrozen() -> Self {
        XCTContext.runActivity(named: "Verify card is frozen (Unfreeze row present)") { _ in
            waitAndAssertTrue(freezeRowFrozen, timeout: .networkRequest, "Unfreeze row should be displayed after freezing")
            return self
        }
    }

    @discardableResult
    func verifyCardActive() -> Self {
        XCTContext.runActivity(named: "Verify card is active (Freeze row present)") { _ in
            waitAndAssertTrue(freezeRowActive, timeout: .networkRequest, "Freeze row should be displayed when card is active")
            return self
        }
    }

    @discardableResult
    func tapShowDetails() -> Self {
        XCTContext.runActivity(named: "Tap Show details on the card") { _ in
            showDetailsButton.waitAndTap()
            return self
        }
    }

    @discardableResult
    func waitForRevealedDetails() -> Self {
        XCTContext.runActivity(named: "Wait for card details to be revealed") { _ in
            waitAndAssertTrue(cardNumberValue, timeout: .networkRequest, "Card number value should be displayed after reveal")
            waitAndAssertTrue(cardExpirationValue, "Card expiration value should be displayed after reveal")
            waitAndAssertTrue(cardCvcValue, "Card CVC value should be displayed after reveal")
            return self
        }
    }

    func readCardNumber() -> String {
        XCTContext.runActivity(named: "Read card number") { _ in
            waitAndAssertTrue(cardNumberValue, timeout: .networkRequest, "Card number should be displayed")
            return cardNumberValue.label
        }
    }

    func readCardExpiration() -> String {
        XCTContext.runActivity(named: "Read card expiration") { _ in
            waitAndAssertTrue(cardExpirationValue, "Card expiration should be displayed")
            return cardExpirationValue.label
        }
    }

    func readCardCvc() -> String {
        XCTContext.runActivity(named: "Read card CVC") { _ in
            waitAndAssertTrue(cardCvcValue, "Card CVC should be displayed")
            return cardCvcValue.label
        }
    }

    @discardableResult
    func tapCopyCardNumber() -> Self {
        XCTContext.runActivity(named: "Tap copy card number") { _ in
            copyNumberButton.waitAndTap()
            return self
        }
    }

    @discardableResult
    func tapCopyExpiration() -> Self {
        XCTContext.runActivity(named: "Tap copy expiration date") { _ in
            copyExpirationButton.waitAndTap()
            return self
        }
    }

    @discardableResult
    func tapCopyCvc() -> Self {
        XCTContext.runActivity(named: "Tap copy CVC") { _ in
            copyCvcButton.waitAndTap()
            return self
        }
    }

    @discardableResult
    func verifyToastVisible(text: String) -> Self {
        XCTContext.runActivity(named: "Verify toast '\(text)' is visible") { _ in
            let toast = app.staticTexts[text].firstMatch
            waitAndAssertTrue(toast, timeout: .conditional, "Toast with text '\(text)' should be displayed")
            return self
        }
    }

    @discardableResult
    func verifyPasteboard(equals expected: String) -> Self {
        XCTContext.runActivity(named: "Verify pasteboard equals '\(expected)'") { _ in
            let actual = UIPasteboard.general.string ?? ""
            XCTAssertEqual(
                actual,
                expected,
                "Pasteboard should contain '\(expected)' but was '\(actual)'"
            )
            return self
        }
    }
}

enum TangemPayCardDetailsScreenElement: String, UIElement {
    case changePinRow
    case freezeCardRowStateActive
    case freezeCardRowStateFrozen
    case cardDetailsShowButton
    case cardDetailsHideButton
    case cardDetailsNumberValue
    case cardDetailsExpirationValue
    case cardDetailsCvcValue
    case cardDetailsCopyNumber
    case cardDetailsCopyExpiration
    case cardDetailsCopyCvc

    var accessibilityIdentifier: String {
        switch self {
        case .changePinRow:
            TangemPayAccessibilityIdentifiers.changePinRow
        case .freezeCardRowStateActive:
            TangemPayAccessibilityIdentifiers.freezeCardRowStateActive
        case .freezeCardRowStateFrozen:
            TangemPayAccessibilityIdentifiers.freezeCardRowStateFrozen
        case .cardDetailsShowButton:
            TangemPayAccessibilityIdentifiers.cardDetailsShowButton
        case .cardDetailsHideButton:
            TangemPayAccessibilityIdentifiers.cardDetailsHideButton
        case .cardDetailsNumberValue:
            TangemPayAccessibilityIdentifiers.cardDetailsNumberValue
        case .cardDetailsExpirationValue:
            TangemPayAccessibilityIdentifiers.cardDetailsExpirationValue
        case .cardDetailsCvcValue:
            TangemPayAccessibilityIdentifiers.cardDetailsCvcValue
        case .cardDetailsCopyNumber:
            TangemPayAccessibilityIdentifiers.cardDetailsCopyNumber
        case .cardDetailsCopyExpiration:
            TangemPayAccessibilityIdentifiers.cardDetailsCopyExpiration
        case .cardDetailsCopyCvc:
            TangemPayAccessibilityIdentifiers.cardDetailsCopyCvc
        }
    }
}
