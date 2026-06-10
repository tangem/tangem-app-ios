//
//  AccountFormScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//

import XCTest
import TangemAccessibilityIdentifiers

final class AccountFormScreen: ScreenBase<AccountFormScreenElement> {
    private lazy var nameInput = textField(.nameInput)
    private lazy var mainButton = button(.mainButton)
    private lazy var closeButton = button(.closeButton)

    // MARK: - Actions

    @discardableResult
    func typeName(_ name: String) -> Self {
        XCTContext.runActivity(named: "Type account name: '\(name)'") { _ in
            nameInput.waitAndTap()
            nameInput.typeText(name)
            dismissKeyboard()
            return self
        }
    }

    @discardableResult
    func clearNameAndType(_ name: String) -> Self {
        XCTContext.runActivity(named: "Clear name and type: '\(name)'") { _ in
            scrollToElement(nameInput)
            let clearButton = app.buttons["Clear text"].firstMatch
            if !nameInput.hasFocus {
                nameInput.tap()
            }
            if clearButton.exists {
                clearButton.tap()
            }
            nameInput.typeText(name)
            dismissKeyboard()
            return self
        }
    }

    @discardableResult
    func clearName() -> Self {
        XCTContext.runActivity(named: "Clear account name") { _ in
            deleteText(element: nameInput)
            dismissKeyboard()
            return self
        }
    }

    private func dismissKeyboard() {
        let doneButton = app.buttons["Done"]
        if doneButton.exists {
            doneButton.tap()
        }
    }

    @discardableResult
    func tapMainButton() -> Self {
        XCTContext.runActivity(named: "Tap main button (Add account / Save)") { _ in
            mainButton.waitAndTap()
            return self
        }
    }

    @discardableResult
    func tapCloseButton() -> Self {
        XCTContext.runActivity(named: "Tap close button") { _ in
            closeButton.waitAndTap()
            return self
        }
    }

    // MARK: - Alert Actions

    @discardableResult
    func tapKeepEditing() -> Self {
        XCTContext.runActivity(named: "Tap 'Keep Editing' in unsaved changes alert") { _ in
            let alert = app.alerts.firstMatch
            waitAndAssertTrue(alert, "Unsaved changes alert should be displayed")
            alert.buttons["Keep Editing"].waitAndTap()
            return self
        }
    }

    func tapDiscard() -> CardSettingsScreen {
        XCTContext.runActivity(named: "Tap 'Discard' in unsaved changes alert") { _ in
            let alert = app.alerts.firstMatch
            waitAndAssertTrue(alert, "Unsaved changes alert should be displayed")
            alert.buttons["Discard"].waitAndTap()
            return CardSettingsScreen(app)
        }
    }

    @discardableResult
    func dismissErrorAlert(buttonTitle: String = "OK") -> Self {
        XCTContext.runActivity(named: "Dismiss error alert") { _ in
            let alert = app.alerts.firstMatch
            waitAndAssertTrue(alert, "Error alert should be displayed")
            alert.buttons[buttonTitle].waitAndTap()
            return self
        }
    }

    // MARK: - Verifications

    @discardableResult
    func verifyScreenIsDisplayed() -> Self {
        XCTContext.runActivity(named: "Verify account form screen is displayed") { _ in
            waitAndAssertTrue(nameInput, "Account name input should be visible")
            waitAndAssertTrue(mainButton, "Main button should be visible")
            return self
        }
    }

    @discardableResult
    func verifyMainButtonEnabled() -> Self {
        XCTContext.runActivity(named: "Verify main button is enabled") { _ in
            waitAndAssertTrue(mainButton, "Main button should exist")
            mainButton.waitForState(state: .enabled)
            return self
        }
    }

    @discardableResult
    func verifyMainButtonDisabled() -> Self {
        XCTContext.runActivity(named: "Verify main button is disabled") { _ in
            waitAndAssertTrue(mainButton, "Main button should exist")
            mainButton.waitForState(state: .disabled)
            return self
        }
    }

    @discardableResult
    func verifyNameFieldValue(_ expectedValue: String) -> Self {
        XCTContext.runActivity(named: "Verify name field value is '\(expectedValue)'") { _ in
            waitAndAssertTrue(nameInput, "Wait for name input field")
            // App clamps the name via SwiftUI onChange, so the value settles asynchronously.
            let matched = nameInput.waitForValue(expectedValue)
            let actualValue = nameInput.value as? String ?? ""
            XCTAssertTrue(matched, "Name field value should be '\(expectedValue)' but was '\(actualValue)'")
            return self
        }
    }

    @discardableResult
    func verifyUnsavedChangesAlert() -> Self {
        XCTContext.runActivity(named: "Verify unsaved changes alert is displayed") { _ in
            let alert = app.alerts.firstMatch
            waitAndAssertTrue(alert, "Unsaved changes alert should be displayed")

            let titleText = alert.staticTexts["Unsaved Changes"]
            XCTAssertTrue(titleText.exists, "Alert should have title 'Unsaved Changes'")

            let messageText = alert.staticTexts.element(
                matching: NSPredicate(format: "label CONTAINS %@", "discard new account")
            ).firstMatch
            XCTAssertTrue(messageText.exists, "Alert should contain message about discarding new account")

            return self
        }
    }

    @discardableResult
    func verifyErrorAlert(expectedMessage: String) -> Self {
        XCTContext.runActivity(named: "Verify error alert with message: '\(expectedMessage)'") { _ in
            let alert = app.alerts.firstMatch
            waitAndAssertTrue(alert, "Error alert should be displayed")

            let messageText = alert.staticTexts.element(
                matching: NSPredicate(format: "label CONTAINS[c] %@", expectedMessage)
            ).firstMatch
            XCTAssertTrue(messageText.exists, "Alert should contain message '\(expectedMessage)'")

            return self
        }
    }
}

enum AccountFormScreenElement: String, UIElement {
    case nameInput
    case mainButton
    case closeButton

    var accessibilityIdentifier: String {
        switch self {
        case .nameInput:
            return AccountsAccessibilityIdentifiers.accountFormNameInput
        case .mainButton:
            return AccountsAccessibilityIdentifiers.accountFormMainButton
        case .closeButton:
            return CommonUIAccessibilityIdentifiers.closeButton
        }
    }
}
