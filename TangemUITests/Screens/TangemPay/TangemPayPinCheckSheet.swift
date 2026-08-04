//
//  TangemPayPinCheckSheet.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TangemPayPinCheckSheet: ScreenBase<TangemPayPinCheckSheetElement> {
    private static let errorToastText = "Something went wrong"

    private lazy var title = staticText(.title)
    private lazy var changePinButton = button(.changePinButton)
    private lazy var loader = app.descendants(matching: .any)[TangemPayAccessibilityIdentifiers.pinCheckLoader].firstMatch
    private lazy var pinDigits = app.staticTexts.matching(identifier: TangemPayAccessibilityIdentifiers.pinCheckValue)
    private lazy var errorToast = app.staticTexts
        .matching(NSPredicate(format: NSPredicateFormat.labelContains.rawValue, Self.errorToastText))
        .firstMatch

    @discardableResult
    func waitForSheet() -> Self {
        XCTContext.runActivity(named: "Wait for current PIN sheet") { _ in
            waitAndAssertTrue(title, "Current PIN sheet title should be displayed")
            return self
        }
    }

    @discardableResult
    func verifyLoadingState() -> Self {
        XCTContext.runActivity(named: "Verify current PIN is loading") { _ in
            waitAndAssertTrue(loader, timeout: .conditional, "Loader should be displayed while the current PIN is loading")
            waitAndAssertTrue(changePinButton, "Change PIN-code button should be displayed while the current PIN is loading")
            XCTAssertFalse(changePinButton.isEnabled, "Change PIN-code button should stay disabled while the current PIN is loading")
            return self
        }
    }

    /// The identifier lands on every digit box of the PIN stack, so the value is read from the boxes left to right.
    @discardableResult
    func verifyPin(_ expected: String) -> Self {
        XCTContext.runActivity(named: "Verify current PIN is '\(expected)'") { _ in
            waitAndAssertTrue(
                pinDigits.element(boundBy: 0),
                timeout: .networkRequest,
                "Current PIN should be displayed once it is loaded"
            )

            let revealedPin = pinDigits.allElementsBoundByIndex
                .sorted { $0.frame.minX < $1.frame.minX }
                .map(\.label)
                .joined()
            XCTAssertEqual(revealedPin, expected, "Revealed PIN should be '\(expected)'")
            return self
        }
    }

    @discardableResult
    func tapChangePin() -> TangemPayPinScreen {
        XCTContext.runActivity(named: "Tap Change PIN-code") { _ in
            changePinButton.waitAndTap()
            return TangemPayPinScreen(app)
        }
    }

    @discardableResult
    func verifyErrorToastAndDismissal() -> TangemPayCardDetailsScreen {
        XCTContext.runActivity(named: "Verify current PIN error toast and sheet dismissal") { _ in
            waitAndAssertTrue(errorToast, "Error toast should be displayed when the current PIN cannot be loaded")
            XCTAssertTrue(
                title.waitForNonExistence(timeout: .conditional),
                "Current PIN sheet should be dismissed when the current PIN cannot be loaded"
            )
            return TangemPayCardDetailsScreen(app)
        }
    }
}

enum TangemPayPinCheckSheetElement: String, UIElement {
    case title
    case changePinButton

    var accessibilityIdentifier: String {
        switch self {
        case .title:
            TangemPayAccessibilityIdentifiers.pinCheckTitle
        case .changePinButton:
            TangemPayAccessibilityIdentifiers.pinCheckChangeButton
        }
    }
}
