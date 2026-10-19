//
//  TangemPayBankTransferAmountScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TangemPayBankTransferAmountScreen: ScreenBase<TangemPayBankTransferAmountScreenElement> {
    private lazy var amountField = textField(.amountField)
    private lazy var tokenRow = button(.tokenRow)
    private lazy var continueButton = button(.continueButton)
    private lazy var maxButton = button(.maxButton)
    private lazy var amountError = app.staticTexts[TangemPayBankTransferAmountScreenElement.errorText.accessibilityIdentifier].firstMatch
    private lazy var railRowElements = app.descendants(matching: .any).matching(identifier: TangemPayBankTransferAmountScreenElement.railRow.accessibilityIdentifier)
    private lazy var railRowButton = app.buttons[TangemPayBankTransferAmountScreenElement.railRow.accessibilityIdentifier].firstMatch

    @discardableResult
    func waitForScreen() -> Self {
        XCTContext.runActivity(named: "Wait for the bank transfer amount screen") { _ in
            waitAndAssertTrue(amountField, timeout: .networkRequest, "Amount field should be displayed")
            return self
        }
    }

    @discardableResult
    func verifyTitle(_ title: String) -> Self {
        XCTContext.runActivity(named: "Verify the amount screen title '\(title)'") { _ in
            waitAndAssertTrue(app.staticTexts[title].firstMatch, "Amount screen should be titled '\(title)'")
            return self
        }
    }

    @discardableResult
    func verifySourceToken(symbol: String, network: String) -> Self {
        XCTContext.runActivity(named: "Verify the source token is \(symbol) on \(network)") { _ in
            waitAndAssertTrue(tokenRow, timeout: .networkRequest, "Source token row should be displayed")
            for text in [symbol, network] {
                XCTAssertTrue(tokenRow.label.contains(text), "Source token should mention '\(text)'. Actual: '\(tokenRow.label)'")
            }
            return self
        }
    }

    @discardableResult
    func tapSourceToken() -> TangemPayBankTransferTokenSheet {
        XCTContext.runActivity(named: "Open the source token selector") { _ in
            tokenRow.waitAndTap()
            return TangemPayBankTransferTokenSheet(app).waitForSheet()
        }
    }

    @discardableResult
    func enterAmount(_ amount: String) -> Self {
        XCTContext.runActivity(named: "Enter amount '\(amount)'") { _ in
            waitAndAssertTrue(amountField, "Amount field should be displayed")
            amountField.tap()
            amountField.typeText(amount)
            XCTAssertTrue(
                amountField.waitForValue(where: { Self.withoutGrouping($0).contains(amount) }),
                "Amount field should contain '\(amount)'. Actual: '\(amountField.getValue())'"
            )
            return self
        }
    }

    @discardableResult
    func selectSourceToken(symbol: String, network: TangemPayNetwork) -> TangemPayBankTransferAmountScreen {
        tapSourceToken()
            .selectToken(symbol: symbol, network: network)
            .verifySourceToken(symbol: symbol, network: network.displayName)
    }

    @discardableResult
    func replaceAmount(_ amount: String) -> Self {
        XCTContext.runActivity(named: "Replace the amount with '\(amount)'") { _ in
            waitAndAssertTrue(amountField, "Amount field should be displayed")
            let currentValue = amountField.getValue()
            let deletions = currentValue == amountField.placeholderValue ? 0 : currentValue.count
            amountField.tap()
            if deletions > 0 {
                amountField.doubleTap()
            }
            amountField.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: deletions) + amount)
            XCTAssertTrue(
                amountField.waitForValue(where: { Self.withoutGrouping($0) == amount }),
                "Amount field should read '\(amount)'. Actual: '\(amountField.getValue())'"
            )
            return self
        }
    }

    @discardableResult
    func tapMax() -> Self {
        XCTContext.runActivity(named: "Tap Max") { _ in
            waitAndAssertTrue(maxButton, timeout: .networkRequest, "Max should be displayed")
            maxButton.tapEvenIfNotHittable()
            return self
        }
    }

    @discardableResult
    func verifyAmount(contains amount: String) -> Self {
        XCTContext.runActivity(named: "Verify the amount contains '\(amount)'") { _ in
            XCTAssertTrue(
                amountField.waitForValue(where: { Self.withoutGrouping($0).contains(amount) }),
                "Amount field should contain '\(amount)'. Actual: '\(amountField.getValue())'"
            )
            return self
        }
    }

    @discardableResult
    func verifyAmountError(_ message: String) -> Self {
        XCTContext.runActivity(named: "Verify the amount error '\(message)'") { _ in
            let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", message), object: amountError)
            XCTAssertEqual(
                XCTWaiter().wait(for: [expectation], timeout: .conditional),
                .completed,
                "Amount error should read '\(message)'. Actual: '\(amountError.label)'"
            )
            return self
        }
    }

    @discardableResult
    func verifyNoAmountError() -> Self {
        XCTContext.runActivity(named: "Verify the amount shows no error") { _ in
            let noError = NSPredicate(format: "exists == 0 OR label == ''")
            let expectation = XCTNSPredicateExpectation(predicate: noError, object: amountError)
            XCTAssertEqual(
                XCTWaiter().wait(for: [expectation], timeout: .conditional),
                .completed,
                "Amount should show no error. Actual: '\(amountError.label)'"
            )
            return self
        }
    }

    @discardableResult
    func verifyContinueEnabled(_ isEnabled: Bool) -> Self {
        XCTContext.runActivity(named: "Verify Continue is \(isEnabled ? "enabled" : "disabled")") { _ in
            XCTAssertTrue(
                continueButton.waitForState(state: isEnabled ? .enabled : .disabled, for: .conditional),
                "Continue should be \(isEnabled ? "enabled" : "disabled")"
            )
            return self
        }
    }

    @discardableResult
    func verifyRail(_ rail: TangemPayBankTransferRail) -> Self {
        XCTContext.runActivity(named: "Verify the \(rail.title) route is selected") { _ in
            let displayed = NSPredicate { [railRowElements] _, _ in rail.isDisplayed(by: railRowElements) }
            XCTAssertEqual(
                XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: displayed, object: nil)], timeout: .networkRequest),
                .completed,
                "Route row should show \(rail.texts)"
            )
            return self
        }
    }

    @discardableResult
    func verifyRailNotSelectable() -> Self {
        XCTContext.runActivity(named: "Verify the route can't be changed") { _ in
            waitAndAssertTrue(railRowElements.firstMatch, timeout: .networkRequest, "Route row should be displayed")
            XCTAssertFalse(railRowButton.exists, "Route row should not be tappable")
            return self
        }
    }

    @discardableResult
    func tapRail() -> TangemPayBankTransferRailSheet {
        XCTContext.runActivity(named: "Open the route selector") { _ in
            railRowButton.waitAndTap(timeout: .networkRequest)
            return TangemPayBankTransferRailSheet(app).waitForSheet()
        }
    }

    @discardableResult
    func selectRail(_ rail: TangemPayBankTransferRail) -> TangemPayBankTransferAmountScreen {
        tapRail()
            .select(rail)
            .verifyRail(rail)
    }

    @discardableResult
    func tapContinueToTransferType() -> TangemPayBankTransferWizardScreen {
        tapContinue()
        return TangemPayBankTransferWizardScreen(app)
    }

    @discardableResult
    func tapContinueToAccountType() -> TangemPayBankTransferWizardScreen {
        tapContinue()
        return TangemPayBankTransferWizardScreen(app)
    }

    @discardableResult
    func tapContinueToConfirmation() -> TangemPayBankTransferConfirmScreen {
        tapContinue()
        return TangemPayBankTransferConfirmScreen(app).waitForScreen()
    }

    @discardableResult
    func close() -> TangemPayMainScreen {
        XCTContext.runActivity(named: "Close the bank transfer") { _ in
            guard let closeButton = app.buttons.matching(NSPredicate(format: "label == %@", Localization.commonClose)).firstHittableElement() else {
                XCTFail("Bank transfer Close button should become hittable")
                return TangemPayMainScreen(app)
            }
            closeButton.tap()
            XCTAssertTrue(amountField.waitForNonExistence(timeout: .conditional), "Bank transfer should be dismissed")
            return TangemPayMainScreen(app).waitForScreen()
        }
    }

    private static func withoutGrouping(_ value: String) -> String {
        value.replacingOccurrences(of: Constants.groupingSeparator, with: "")
    }

    private func tapContinue() {
        XCTContext.runActivity(named: "Tap Continue on the amount screen") { _ in
            XCTAssertTrue(continueButton.waitForState(state: .enabled, for: .conditional), "Continue should be enabled")
            continueButton.waitAndTap()
        }
    }
}

enum TangemPayBankTransferAmountScreenElement: String, UIElement {
    case amountField
    case tokenRow
    case continueButton
    case maxButton
    case errorText
    case railRow

    var accessibilityIdentifier: String {
        switch self {
        case .amountField:
            TangemPayOfframpAccessibilityIdentifiers.amountField
        case .tokenRow:
            TangemPayOfframpAccessibilityIdentifiers.amountTokenRow
        case .continueButton:
            TangemPayOfframpAccessibilityIdentifiers.amountContinueButton
        case .maxButton:
            TangemPayOfframpAccessibilityIdentifiers.amountMaxButton
        case .errorText:
            TangemPayOfframpAccessibilityIdentifiers.amountErrorText
        case .railRow:
            TangemPayOfframpAccessibilityIdentifiers.amountRailRow
        }
    }
}

private extension TangemPayBankTransferAmountScreen {
    enum Constants {
        static let groupingSeparator = ","
    }
}
