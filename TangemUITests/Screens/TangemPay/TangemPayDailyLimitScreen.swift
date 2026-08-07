//
//  TangemPayDailyLimitScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TangemPayDailyLimitScreen: ScreenBase<TangemPayDailyLimitScreenElement> {
    static let presetDigits = ["1", "5000", "10000", "25000"]

    private static let hintPrefix = "Set a limit from"
    private static let hintMaxLimit = "250,000"
    private static let errorAlertTitle = "Something went wrong"
    private static let errorAlertMessageFragment = "set the limit"

    private lazy var amountField = textField(.dailyLimitAmountField)
    private lazy var setLimitsButton = button(.dailyLimitSetButton)
    private lazy var successTitle = staticText(.dailyLimitSuccessTitle)
    private lazy var doneButton = button(.dailyLimitDoneButton)

    @discardableResult
    func waitForScreen() -> Self {
        XCTContext.runActivity(named: "Wait for Daily limit screen") { _ in
            waitAndAssertTrue(amountField, "Amount field should be displayed on Daily limit screen")
            waitAndAssertTrue(setLimitsButton, "Set limits button should be displayed on Daily limit screen")
            return self
        }
    }

    @discardableResult
    func verifyScreenDisplayed() -> Self {
        XCTContext.runActivity(named: "Verify Daily limit screen content") { _ in
            waitAndAssertTrue(amountField, "Amount field should be displayed")
            waitAndAssertTrue(setLimitsButton, "Set limits button should be displayed")

            let hint = app.staticTexts
                .matching(NSPredicate(format: "label CONTAINS %@ AND label CONTAINS %@", Self.hintPrefix, Self.hintMaxLimit))
                .firstMatch
            waitAndAssertTrue(hint, "Range hint '\(Self.hintPrefix) … \(Self.hintMaxLimit)' should be displayed")

            for digits in Self.presetDigits {
                waitAndAssertTrue(presetButton(digits), "Quick value button for '\(digits)' should be displayed")
            }
            return self
        }
    }

    @discardableResult
    func tapPreset(_ digits: String) -> Self {
        XCTContext.runActivity(named: "Tap quick value preset '\(digits)'") { _ in
            presetButton(digits).waitAndTap()
            return self
        }
    }

    func readAmountDigits() -> String {
        XCTContext.runActivity(named: "Read amount field digits") { _ in
            waitAndAssertTrue(amountField, "Amount field should be displayed")
            return amountField.getValue().filter(\.isNumber)
        }
    }

    @discardableResult
    func clearAndEnterAmount(_ amount: String) -> Self {
        XCTContext.runActivity(named: "Clear and enter amount '\(amount)'") { _ in
            waitAndAssertTrue(amountField, "Amount field should be displayed")
            clearText(element: amountField)
            typeWithFocus(into: amountField, text: amount)
            return self
        }
    }

    @discardableResult
    func verifySetLimitsDisabled() -> Self {
        XCTContext.runActivity(named: "Verify Set limits button is disabled") { _ in
            waitAndAssertTrue(setLimitsButton, "Set limits button should be displayed")
            setLimitsButton.waitForState(state: .disabled, for: .conditional)
            return self
        }
    }

    @discardableResult
    func tapSetLimits() -> Self {
        XCTContext.runActivity(named: "Tap Set limits") { _ in
            setLimitsButton.waitAndTap()
            return self
        }
    }

    @discardableResult
    func verifySuccessDisplayed() -> Self {
        XCTContext.runActivity(named: "Verify daily limit success screen") { _ in
            waitAndAssertTrue(
                successTitle,
                timeout: .networkRequest,
                "Daily limit success title should be displayed after setting the limit"
            )
            return self
        }
    }

    @discardableResult
    func tapDone() -> TangemPayCardDetailsScreen {
        XCTContext.runActivity(named: "Tap Done on success screen") { _ in
            doneButton.waitAndTap()
            return TangemPayCardDetailsScreen(app)
        }
    }

    @discardableResult
    func verifyErrorAlert() -> Self {
        XCTContext.runActivity(named: "Verify limit change error alert") { _ in
            let alert = app.alerts.firstMatch
            waitAndAssertTrue(alert, timeout: .networkRequest, "Error alert should be displayed after failed limit change")

            let title = alert.staticTexts
                .element(matching: NSPredicate(format: "label CONTAINS %@", Self.errorAlertTitle))
                .firstMatch
            XCTAssertTrue(title.exists, "Alert title '\(Self.errorAlertTitle)' should be displayed")

            let message = alert.staticTexts
                .element(matching: NSPredicate(format: "label CONTAINS %@", Self.errorAlertMessageFragment))
                .firstMatch
            XCTAssertTrue(message.exists, "Alert message containing '\(Self.errorAlertMessageFragment)' should be displayed")

            alert.buttons["OK"].waitAndTap()
            return self
        }
    }

    private func presetButton(_ digits: String) -> XCUIElement {
        app.buttons[TangemPayAccessibilityIdentifiers.dailyLimitPresetButton(digits)].firstMatch
    }
}

enum TangemPayDailyLimitScreenElement: String, UIElement {
    case dailyLimitAmountField
    case dailyLimitSetButton
    case dailyLimitSuccessTitle
    case dailyLimitDoneButton

    var accessibilityIdentifier: String {
        switch self {
        case .dailyLimitAmountField:
            TangemPayAccessibilityIdentifiers.dailyLimitAmountField
        case .dailyLimitSetButton:
            TangemPayAccessibilityIdentifiers.dailyLimitSetButton
        case .dailyLimitSuccessTitle:
            TangemPayAccessibilityIdentifiers.dailyLimitSuccessTitle
        case .dailyLimitDoneButton:
            TangemPayAccessibilityIdentifiers.dailyLimitDoneButton
        }
    }
}
