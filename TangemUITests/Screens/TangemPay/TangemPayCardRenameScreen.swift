//
//  TangemPayCardRenameScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TangemPayCardRenameScreen: ScreenBase<TangemPayCardRenameScreenElement> {
    private static let invalidAlertTitle = "Invalid characters"
    private static let invalidAlertMessage = "Only letters and numbers are allowed"
    private static let backendErrorAlertTitle = "Unable to rename card"
    private static let backendErrorAlertMessage = "Please try again later"

    private lazy var nameField = textField(.cardNameTextField)
    private lazy var doneButton = button(.cardRenameDoneButton)
    private lazy var closeButton = button(.cardRenameCloseButton)

    @discardableResult
    func waitForScreen() -> Self {
        XCTContext.runActivity(named: "Wait for card rename editing screen") { _ in
            waitAndAssertTrue(nameField, "Card name field should be displayed in rename mode")
            waitAndAssertTrue(doneButton, "Done button should be displayed in rename mode")
            return self
        }
    }

    @discardableResult
    func clearAndEnterName(_ name: String) -> Self {
        XCTContext.runActivity(named: "Clear and enter card name '\(name)'") { _ in
            waitAndAssertTrue(nameField, "Card name field should be displayed")
            clearText(element: nameField)
            typeWithFocus(into: nameField, text: name)
            return self
        }
    }

    @discardableResult
    func clearName() -> Self {
        XCTContext.runActivity(named: "Clear card name field") { _ in
            waitAndAssertTrue(nameField, "Card name field should be displayed")
            clearText(element: nameField)
            return self
        }
    }

    @discardableResult
    func verifyDoneDisabled() -> Self {
        XCTContext.runActivity(named: "Verify Done button is disabled") { _ in
            waitAndAssertTrue(doneButton, "Done button should be displayed")
            doneButton.waitForState(state: .disabled, for: .conditional)
            return self
        }
    }

    @discardableResult
    func submitExpectingSuccess() -> TangemPayCardDetailsScreen {
        XCTContext.runActivity(named: "Tap Done expecting successful rename") { _ in
            doneButton.waitAndTap()
            return TangemPayCardDetailsScreen(app)
        }
    }

    @discardableResult
    func submitExpectingInvalidCharacters() -> Self {
        XCTContext.runActivity(named: "Tap Done expecting Invalid characters alert") { _ in
            doneButton.waitAndTap()
            verifyAlert(title: Self.invalidAlertTitle, message: Self.invalidAlertMessage)
            return self
        }
    }

    @discardableResult
    func submitExpectingBackendError() -> Self {
        XCTContext.runActivity(named: "Tap Done expecting backend error alert") { _ in
            doneButton.waitAndTap()
            verifyAlert(title: Self.backendErrorAlertTitle, message: Self.backendErrorAlertMessage, timeout: .networkRequest)
            return self
        }
    }

    @discardableResult
    func close() -> TangemPayCardDetailsScreen {
        XCTContext.runActivity(named: "Close rename mode") { _ in
            closeButton.waitAndTap()
            return TangemPayCardDetailsScreen(app)
        }
    }

    private func verifyAlert(title: String, message: String, timeout: TimeInterval = .robustUIUpdate) {
        let alert = app.alerts.firstMatch
        waitAndAssertTrue(alert, timeout: timeout, "Alert '\(title)' should be displayed")

        let titleElement = alert.staticTexts
            .element(matching: NSPredicate(format: "label CONTAINS %@", title))
            .firstMatch
        waitAndAssertTrue(titleElement, "Alert title '\(title)' should be displayed")

        let messageElement = alert.staticTexts
            .element(matching: NSPredicate(format: "label CONTAINS %@", message))
            .firstMatch
        waitAndAssertTrue(messageElement, "Alert message '\(message)' should be displayed")

        alert.buttons["OK"].waitAndTap()
    }
}

enum TangemPayCardRenameScreenElement: String, UIElement {
    case cardNameTextField
    case cardRenameDoneButton
    case cardRenameCloseButton

    var accessibilityIdentifier: String {
        switch self {
        case .cardNameTextField:
            TangemPayAccessibilityIdentifiers.cardNameTextField
        case .cardRenameDoneButton:
            TangemPayAccessibilityIdentifiers.cardRenameDoneButton
        case .cardRenameCloseButton:
            TangemPayAccessibilityIdentifiers.cardRenameCloseButton
        }
    }
}
