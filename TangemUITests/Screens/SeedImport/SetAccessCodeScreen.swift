//
//  SetAccessCodeScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class SetAccessCodeScreen: ScreenBase<SetAccessCodeScreenElement> {
    private lazy var title = staticText(.title)
    // Identifier is shared by the visible pin stack (Other) and a hidden zero-opacity TextField; only the stack is tappable.
    private lazy var pinStack = otherElement(.input)
    private lazy var skipButton = button(.skipButton)

    @discardableResult
    func skipAccessCode(timeout: TimeInterval = .networkRequest) -> SeedImportSuccessScreen {
        XCTContext.runActivity(named: "Skip access code") { _ in
            skipButton.tap()

            // Confirm skipping if alert is shown.
            let alert = app.alerts.firstMatch
            if alert.waitForExistence(timeout: .robustUIUpdate) {
                alert.buttons["Skip anyway"].tap()
            }

            return SeedImportSuccessScreen(app)
        }
    }

    @discardableResult
    func setAccessCode(_ code: String) -> SeedImportSuccessScreen {
        XCTContext.runActivity(named: "Set access code") { _ in
            enterCodeDigitByDigit(code)

            let confirmTitle = app.staticTexts.matching(
                NSPredicate(
                    format: "identifier == %@ AND label == %@",
                    OnboardingAccessibilityIdentifiers.title,
                    "Re-enter access code"
                )
            ).firstMatch
            waitAndAssertTrue(confirmTitle, "Access code confirmation step should be displayed")
            enterCodeDigitByDigit(code)

            return SeedImportSuccessScreen(app)
        }
    }

    /// The form intermittently drops focus and swallows keystrokes, so entry is driven by the filled-dots count.
    private func enterCodeDigitByDigit(_ code: String) {
        let hiddenField = app.textFields[OnboardingAccessibilityIdentifiers.accessCodeInputField].firstMatch
        waitAndAssertTrue(hiddenField, "Access code input field should exist")
        XCTAssertTrue(waitForEnteredDigits { $0 == 0 }, "Access code field should start empty")

        let digits = Array(code)
        var attempts = 0

        while enteredDigitsCount() < digits.count {
            XCTAssertLessThan(attempts, digits.count * 3, "Access code entry keeps losing typed digits")
            attempts += 1

            ensurePinFieldFocus(hiddenField)
            let nextIndex = enteredDigitsCount()
            guard nextIndex < digits.count else { return }

            hiddenField.typeText(String(digits[nextIndex]))
            let expectedCount = nextIndex + 1
            // Soft wait on purpose: a swallowed digit is retyped on the next pass, the attempts cap fails the test.
            waitForEnteredDigits { $0 >= expectedCount }
        }
    }

    private func enteredDigitsCount() -> Int {
        pinStack.staticTexts.matching(NSPredicate(format: "label == %@", "•")).count
    }

    @discardableResult
    private func waitForEnteredDigits(_ matches: @escaping (Int) -> Bool) -> Bool {
        let predicate = NSPredicate { [weak self] _, _ in
            guard let self else { return false }
            return matches(enteredDigitsCount())
        }
        return XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: predicate, object: NSObject())], timeout: .shortUIUpdate) == .completed
    }

    /// The stack's AX frame is flaky, so refocusing taps by coordinate instead of hit point.
    private func ensurePinFieldFocus(_ hiddenField: XCUIElement) {
        let focused = NSPredicate(format: "hasKeyboardFocus == true")

        if XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: focused, object: hiddenField)], timeout: .shortUIUpdate) == .completed {
            return
        }

        pinStack.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertEqual(
            XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: focused, object: hiddenField)], timeout: .robustUIUpdate),
            .completed,
            "Access code input field should get keyboard focus"
        )
    }
}

enum SetAccessCodeScreenElement: String, UIElement {
    case title
    case input
    case skipButton

    var accessibilityIdentifier: String {
        switch self {
        case .title:
            return OnboardingAccessibilityIdentifiers.title
        case .input:
            return OnboardingAccessibilityIdentifiers.accessCodeInputField
        case .skipButton:
            return OnboardingAccessibilityIdentifiers.accessCodeSkipButton
        }
    }
}
