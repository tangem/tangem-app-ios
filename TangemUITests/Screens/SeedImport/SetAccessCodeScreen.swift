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

    /// Both steps share the field id; the title distinguishes them.
    private var confirmStepTitle: XCUIElement {
        app.staticTexts.matching(
            NSPredicate(
                format: "identifier == %@ AND label == %@",
                OnboardingAccessibilityIdentifiers.title,
                "Re-enter access code"
            )
        ).firstMatch
    }

    private var successFinishButton: XCUIElement {
        app.buttons[OnboardingAccessibilityIdentifiers.seedImportSuccessFinishButton].firstMatch
    }

    @discardableResult
    func setAccessCode(_ code: String) -> SeedImportSuccessScreen {
        XCTContext.runActivity(named: "Set access code") { _ in
            let hiddenField = app.textFields[OnboardingAccessibilityIdentifiers.accessCodeInputField].firstMatch
            // Create step auto-advances to confirm once the code is full.
            enterCode(code, into: hiddenField) { [self] in confirmStepTitle.exists }
            // Field id lingers as a hidden field, so wait for the success screen, not the field to vanish.
            enterCode(code, into: hiddenField) { [self] in successFinishButton.exists }
            return SeedImportSuccessScreen(app)
        }
    }

    /// Steps auto-advance and swallow keystrokes, so entry stops on the step transition (doneWhen), not a digit count.
    private func enterCode(_ code: String, into hiddenField: XCUIElement, doneWhen: @escaping () -> Bool) {
        waitAndAssertTrue(hiddenField, "Access code input field should exist")
        XCTAssertTrue(waitForEnteredDigits(timeout: .robustUIUpdate) { $0 == 0 }, "Access code field should start empty")

        let digits = Array(code)
        var attempts = 0

        while enteredDigitsCount() < digits.count {
            if doneWhen() { return }
            XCTAssertLessThan(attempts, digits.count * 3, "Access code entry keeps losing typed digits")
            attempts += 1

            ensurePinFieldFocus(hiddenField)
            let nextIndex = enteredDigitsCount()
            guard nextIndex < digits.count else { break }

            hiddenField.typeText(String(digits[nextIndex]))
            // Soft wait on purpose: a swallowed digit is retyped on the next pass, the attempts cap fails the test.
            waitForEnteredDigits { $0 >= nextIndex + 1 }
        }

        XCTAssertTrue(waitForCondition(doneWhen), "Access code step did not advance after the full code was entered")
    }

    private func enteredDigitsCount() -> Int {
        pinStack.staticTexts.matching(NSPredicate(format: "label == %@", "•")).count
    }

    @discardableResult
    private func waitForEnteredDigits(timeout: TimeInterval = .shortUIUpdate, _ matches: @escaping (Int) -> Bool) -> Bool {
        let predicate = NSPredicate { [weak self] _, _ in
            guard let self else { return false }
            return matches(enteredDigitsCount())
        }
        return XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: predicate, object: NSObject())], timeout: timeout) == .completed
    }

    @discardableResult
    private func waitForCondition(_ condition: @escaping () -> Bool, timeout: TimeInterval = .robustUIUpdate) -> Bool {
        let predicate = NSPredicate { _, _ in condition() }
        return XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: predicate, object: NSObject())], timeout: timeout) == .completed
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
